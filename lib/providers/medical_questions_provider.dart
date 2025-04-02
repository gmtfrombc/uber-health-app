import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient_request.dart';

class MedicalQuestion {
  final String id;
  final String question;
  final String summary;
  final DateTime timestamp;
  final String status; // 'pending' or 'answered'
  final String? providerResponse;
  final String? providerId;
  final String? providerName;

  MedicalQuestion({
    required this.id,
    required this.question,
    required this.summary,
    required this.timestamp,
    required this.status,
    this.providerResponse,
    this.providerId,
    this.providerName,
  });

  factory MedicalQuestion.fromPatientRequest(
    PatientRequest request, {
    String? extractedQuestion,
  }) {
    return MedicalQuestion(
      id: request.id,
      question: extractedQuestion ?? 'Medical question',
      summary: request.triageSummaryId ?? '',
      timestamp: request.timestamp,
      status: request.status == RequestStatus.pending ? 'pending' : 'answered',
      providerResponse: null,
      providerId: request.providerId,
      providerName: null,
    );
  }

  factory MedicalQuestion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Extract the first patient message as the "question"
    String extractedQuestion = 'Medical question';
    if (data['messages'] != null &&
        data['messages'] is List &&
        (data['messages'] as List).isNotEmpty) {
      final messages = data['messages'] as List;
      for (var msg in messages) {
        if (msg['sender'] == 'patient') {
          extractedQuestion = msg['content'] ?? extractedQuestion;
          break;
        }
      }
    }

    // Get the status directly from Firebase document
    final String documentStatus =
        data['status']?.toString().toLowerCase() ?? 'pending';

    // Check if there's a provider response
    final hasProviderResponse =
        data['providerResponse'] != null &&
        data['providerResponse'].toString().trim().isNotEmpty;

    // Set UI status based on document status and provider response
    String uiStatus = documentStatus;
    if (documentStatus == 'pending' || documentStatus == 'triaged') {
      // For the UI, show as 'pending' if no provider response
      uiStatus = hasProviderResponse ? 'answered' : 'pending';
    }

    debugPrint(
      'Document ${doc.id} status: $documentStatus, UI status: $uiStatus',
    );

    return MedicalQuestion(
      id: doc.id,
      question: extractedQuestion,
      summary: data['aiTriageSummary'] ?? '',
      timestamp:
          (data['createdAt'] != null)
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      status: uiStatus,
      providerResponse: data['providerResponse'],
      providerId: data['providerId'],
      providerName: data['providerName'],
    );
  }
}

class MedicalQuestionsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<MedicalQuestion> _questions = [];
  bool _isLoading = false;

  List<MedicalQuestion> get questions => _questions;
  bool get isLoading => _isLoading;

  // Get questions that are pending or answered
  List<MedicalQuestion> get pendingQuestions =>
      _questions.where((q) => q.status == 'pending').toList();

  List<MedicalQuestion> get answeredQuestions =>
      _questions.where((q) => q.status == 'answered').toList();

  Future<void> refreshQuestions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('Fetching medical questions for user ${user.uid}');

      // Use a simpler query without multiple inequality filters
      // First, fetch all medical questions for this user
      final snapshot =
          await _firestore
              .collection('conversations')
              .where('patientId', isEqualTo: user.uid)
              .where('requestType', isEqualTo: RequestType.medicalQuestion.name)
              .orderBy('createdAt', descending: true)
              .get();

      debugPrint('Found ${snapshot.docs.length} medical questions');

      // Then filter out resolved/cancelled ones in memory
      final allQuestions =
          snapshot.docs
              .map((doc) => MedicalQuestion.fromFirestore(doc))
              .toList();

      _questions =
          allQuestions.where((question) {
            // Check if the status is not resolved or cancelled
            return question.status != 'resolved' &&
                ![
                  'resolved',
                  'cancelled',
                ].contains(question.status.toLowerCase());
          }).toList();

      debugPrint(
        'After filtering: ${_questions.length} active medical questions',
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching medical questions: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markQuestionAsResolved(String questionId) async {
    try {
      // Update the status to 'resolved' in Firebase
      await _firestore.collection('conversations').doc(questionId).update({
        'status': 'resolved',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Question $questionId marked as resolved in Firebase');

      // Update local state
      final index = _questions.indexWhere((q) => q.id == questionId);
      if (index >= 0) {
        final updatedQuestions = List<MedicalQuestion>.from(_questions);
        updatedQuestions.removeAt(index);
        _questions = updatedQuestions;
        notifyListeners();
      }

      // Immediately refresh questions to ensure the UI is up to date
      await refreshQuestions();

      return true;
    } catch (e) {
      debugPrint('Error marking question as resolved: $e');
      return false;
    }
  }

  Future<MedicalQuestion?> getQuestionDetails(String questionId) async {
    try {
      final doc =
          await _firestore.collection('conversations').doc(questionId).get();

      if (!doc.exists) return null;

      final questionData = MedicalQuestion.fromFirestore(doc);

      // If there's a provider ID, try to get their name
      if (questionData.providerId != null &&
          questionData.providerId!.isNotEmpty) {
        try {
          final providerDoc =
              await _firestore
                  .collection('providers')
                  .doc(questionData.providerId)
                  .get();

          if (providerDoc.exists) {
            final providerData = providerDoc.data();
            final String firstName = providerData?['firstName'] ?? '';
            final String lastName = providerData?['lastName'] ?? '';
            final String credentials = providerData?['credentials'] ?? '';

            // Create a new MedicalQuestion with the provider name
            return MedicalQuestion(
              id: questionData.id,
              question: questionData.question,
              summary: questionData.summary,
              timestamp: questionData.timestamp,
              status: questionData.status,
              providerResponse: questionData.providerResponse,
              providerId: questionData.providerId,
              providerName: '$firstName $lastName, $credentials'.trim(),
            );
          }
        } catch (e) {
          debugPrint('Error fetching provider details: $e');
          // Continue with the original question data
        }
      }

      return questionData;
    } catch (e) {
      debugPrint('Error fetching question details: $e');
      return null;
    }
  }
}
