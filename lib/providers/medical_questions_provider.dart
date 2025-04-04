import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
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
  final bool isRead; // Track if the answered question has been read

  MedicalQuestion({
    required this.id,
    required this.question,
    required this.summary,
    required this.timestamp,
    required this.status,
    this.providerResponse,
    this.providerId,
    this.providerName,
    this.isRead = false,
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
      isRead: false,
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

    // Get creation date
    DateTime createdAt = DateTime.now();
    if (data['createdAt'] != null) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    }

    // Get the last time the provider responded, if available
    DateTime? providerResponseTimestamp;
    if (data['providerResponseTimestamp'] != null) {
      providerResponseTimestamp =
          (data['providerResponseTimestamp'] as Timestamp).toDate();
    }

    // Check if the question has been read by the user
    final bool isExplicitlyRead = data['isRead'] ?? false;

    // Logic for determining if a question should be marked as read:
    // 1. If it's explicitly marked as read in Firestore, respect that
    // 2. For answered questions, check if the answer is recent and show as unread
    bool isRead;

    if (uiStatus == 'answered') {
      // For answered questions, check if explicitly read or if answer is recent
      if (isExplicitlyRead) {
        // If explicitly marked as read, respect that setting
        isRead = true;
      } else if (providerResponseTimestamp != null) {
        // If this question was recently answered (last 48 hours), show it as unread
        // Unless it's been explicitly marked as read
        final Duration sinceResponse = DateTime.now().difference(
          providerResponseTimestamp,
        );
        isRead = sinceResponse.inHours > 48; // Older than 48 hours = auto-read
      } else {
        // Default to unread for answered questions with no timestamp
        isRead = false;
      }
    } else {
      // Pending questions are considered "read" (don't need attention)
      isRead = true;
    }

    debugPrint(
      'Document ${doc.id} status: $documentStatus, UI status: $uiStatus, isRead: $isRead (explicit: $isExplicitlyRead)',
    );

    return MedicalQuestion(
      id: doc.id,
      question: extractedQuestion,
      summary: data['aiTriageSummary'] ?? '',
      timestamp: createdAt,
      status: uiStatus,
      providerResponse: data['providerResponse'],
      providerId: data['providerId'],
      providerName: data['providerName'],
      isRead: isRead,
    );
  }

  // Create a copy of the question with updated properties
  MedicalQuestion copyWith({
    String? id,
    String? question,
    String? summary,
    DateTime? timestamp,
    String? status,
    String? providerResponse,
    String? providerId,
    String? providerName,
    bool? isRead,
  }) {
    return MedicalQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      summary: summary ?? this.summary,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      providerResponse: providerResponse ?? this.providerResponse,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      isRead: isRead ?? this.isRead,
    );
  }
}

class MedicalQuestionsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<MedicalQuestion> _questions = [];
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _questionsSubscription;

  List<MedicalQuestion> get questions => _questions;
  bool get isLoading => _isLoading;

  // Get questions that are pending or answered
  List<MedicalQuestion> get pendingQuestions =>
      _questions.where((q) => q.status == 'pending').toList();

  List<MedicalQuestion> get answeredQuestions =>
      _questions.where((q) => q.status == 'answered').toList();

  // Questions that need attention - either pending or ALL answered questions until resolved
  List<MedicalQuestion> get questionsNeedingAttention {
    final result =
        _questions
            .where(
              (q) =>
                  q.status.toLowerCase() == 'pending' ||
                  q.status.toLowerCase() ==
                      'answered', // Include ALL answered questions regardless of read status
            )
            .toList();

    // Log the questions needing attention
    debugPrint('Questions needing attention: ${result.length}');
    for (final q in result) {
      debugPrint(
        'Question ${q.id} needs attention: status=${q.status}, isRead=${q.isRead}',
      );
    }

    return result;
  }

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

  // Subscribe to real-time updates for the user's medical questions
  void startRealTimeUpdates() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Cancel existing subscription if any
    _questionsSubscription?.cancel();

    // Create a new subscription
    _questionsSubscription = _firestore
        .collection('conversations')
        .where('patientId', isEqualTo: user.uid)
        .where('requestType', isEqualTo: RequestType.medicalQuestion.name)
        .snapshots()
        .listen(
          (snapshot) {
            debugPrint(
              'Received real-time update with ${snapshot.docs.length} medical questions',
            );

            // Process the updated data
            final allQuestions =
                snapshot.docs
                    .map((doc) => MedicalQuestion.fromFirestore(doc))
                    .toList();

            // Track if any questions changed from pending to answered
            List<MedicalQuestion> updatedQuestions = [];

            // For each question in the update, check if it changed from pending to answered
            for (final newQuestion in allQuestions) {
              // Find if we already have this question
              final existingIndex = _questions.indexWhere(
                (q) => q.id == newQuestion.id,
              );

              if (existingIndex >= 0) {
                final existingQuestion = _questions[existingIndex];

                // If a question changed from pending to answered, mark it as unread
                if (existingQuestion.status == 'pending' &&
                    newQuestion.status == 'answered') {
                  debugPrint(
                    'Question ${newQuestion.id} changed from pending to answered',
                  );

                  // Create a modified question with isRead=false and store the response timestamp
                  // This ensures we can track when the question was answered
                  try {
                    // First, update Firestore to add providerResponseTimestamp
                    _firestore
                        .collection('conversations')
                        .doc(newQuestion.id)
                        .update({
                          'providerResponseTimestamp':
                              FieldValue.serverTimestamp(),
                          'isRead': false,
                        });

                    debugPrint(
                      'Added providerResponseTimestamp to question ${newQuestion.id}',
                    );
                  } catch (e) {
                    debugPrint('Error updating providerResponseTimestamp: $e');
                  }

                  // Add to local list with isRead=false
                  updatedQuestions.add(newQuestion.copyWith(isRead: false));
                } else {
                  updatedQuestions.add(newQuestion);
                }
              } else {
                updatedQuestions.add(newQuestion);
              }
            }

            // Filter out resolved/cancelled questions
            _questions =
                updatedQuestions.where((question) {
                  return question.status != 'resolved' &&
                      ![
                        'resolved',
                        'cancelled',
                      ].contains(question.status.toLowerCase());
                }).toList();

            // Notify listeners about the change
            notifyListeners();
            debugPrint(
              'Updated questions in real-time: ${_questions.length} active questions',
            );
          },
          onError: (error) {
            debugPrint('Error in real-time questions update: $error');
          },
        );
  }

  // Stop real-time updates when they're no longer needed
  void stopRealTimeUpdates() {
    _questionsSubscription?.cancel();
    _questionsSubscription = null;
  }

  @override
  void dispose() {
    stopRealTimeUpdates();
    super.dispose();
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

      return true;
    } catch (e) {
      debugPrint('Error marking question as resolved: $e');
      return false;
    }
  }

  // Get a question with updated info from Firestore
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
              isRead: questionData.isRead,
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

  // Mark a question as read
  Future<bool> markQuestionAsRead(String questionId) async {
    try {
      // Update the isRead flag in Firebase
      await _firestore.collection('conversations').doc(questionId).update({
        'isRead': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Question $questionId marked as read in Firebase');

      // Update local state
      final index = _questions.indexWhere((q) => q.id == questionId);
      if (index >= 0) {
        final updatedQuestions = List<MedicalQuestion>.from(_questions);
        updatedQuestions[index] = updatedQuestions[index].copyWith(
          isRead: true,
        );
        _questions = updatedQuestions;
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error marking question as read: $e');
      return false;
    }
  }

  // Call this method when a user explicitly marks a question as done
  Future<bool> markQuestionAsDone(String questionId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // For both pending and answered questions, mark as resolved to remove from active list
      await _firestore.collection('conversations').doc(questionId).update({
        'status':
            'resolved', // Mark as resolved to remove from active questions
        'isRead': true, // Also mark as read (redundant but for clarity)
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local state - remove from list since it's resolved
      final index = _questions.indexWhere((q) => q.id == questionId);
      if (index >= 0) {
        final updatedQuestions = List<MedicalQuestion>.from(_questions);
        updatedQuestions.removeAt(index);
        _questions = updatedQuestions;
        notifyListeners();
      }

      // Log the update
      debugPrint('Question $questionId marked as resolved (done)');

      return true;
    } catch (e) {
      debugPrint('Error marking question as done: $e');
      return false;
    }
  }
}
