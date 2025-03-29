import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/message.dart';

class ConsultationRequest {
  final String id;
  final String patientId;
  final String requestType;
  final String urgency;
  final String category;
  final String providerType;
  final String status;
  final DateTime createdAt;
  final List<Message> messages;
  final String? aiTriageSummary;
  final String? providerResponse;
  final String? providerInstructions;
  final DateTime? scheduledDateTime;

  ConsultationRequest({
    required this.id,
    required this.patientId,
    required this.requestType,
    required this.urgency,
    required this.category,
    required this.providerType,
    required this.status,
    required this.createdAt,
    required this.messages,
    this.aiTriageSummary,
    this.providerResponse,
    this.providerInstructions,
    this.scheduledDateTime,
  });

  factory ConsultationRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse timestamp
    DateTime createdAt = DateTime.now();
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        createdAt = DateTime.parse(data['createdAt'] as String);
      }
    }

    // Parse scheduledDateTime if exists
    DateTime? scheduledDateTime;
    if (data['scheduledDateTime'] != null) {
      if (data['scheduledDateTime'] is Timestamp) {
        scheduledDateTime = (data['scheduledDateTime'] as Timestamp).toDate();
      } else if (data['scheduledDateTime'] is int) {
        scheduledDateTime = DateTime.fromMillisecondsSinceEpoch(
          data['scheduledDateTime'] as int,
        );
      }
    }

    // Parse messages
    List<Message> messages = [];
    if (data['messages'] != null && data['messages'] is List) {
      try {
        messages =
            (data['messages'] as List).map((msg) {
              try {
                if (msg is Map<String, dynamic>) {
                  return Message.fromMap(msg);
                } else {
                  debugPrint('⚠️ Message is not a Map: ${msg.runtimeType}');
                  return Message(
                    sender: 'system',
                    text: 'Invalid message format',
                    timestamp: DateTime.now(),
                  );
                }
              } catch (e) {
                debugPrint('⚠️ Error parsing message: $e');
                return Message(
                  sender: 'system',
                  text: 'Error parsing message',
                  timestamp: DateTime.now(),
                );
              }
            }).toList();
      } catch (e) {
        debugPrint('⚠️ Error parsing messages: $e');
      }
    }

    return ConsultationRequest(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      requestType: data['requestType'] ?? 'medicalQuestion',
      urgency: data['urgency'] ?? 'Routine',
      category: data['category'] ?? 'General',
      providerType: data['providerType'] ?? 'medicalProvider',
      status: data['status'] ?? 'pending',
      createdAt: createdAt,
      messages: messages,
      aiTriageSummary: data['aiTriageSummary'],
      providerResponse: data['providerResponse'],
      providerInstructions: data['providerInstructions'],
      scheduledDateTime: scheduledDateTime,
    );
  }

  // Format the scheduled date and time for display
  String get formattedScheduledDateTime {
    if (scheduledDateTime == null) return 'Not scheduled';

    final date =
        '${scheduledDateTime!.month}/${scheduledDateTime!.day}/${scheduledDateTime!.year}';
    final hour =
        scheduledDateTime!.hour > 12
            ? scheduledDateTime!.hour - 12
            : (scheduledDateTime!.hour == 0 ? 12 : scheduledDateTime!.hour);
    final minute = scheduledDateTime!.minute.toString().padLeft(2, '0');
    final ampm = scheduledDateTime!.hour >= 12 ? 'PM' : 'AM';

    return '$date at $hour:$minute $ampm';
  }
}

class ProviderDashboardProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Provider data
  UserModel? currentProvider;

  // Dashboard data
  List<ConsultationRequest> _urgentRequests = [];
  List<ConsultationRequest> _scheduledRequests = [];
  List<ConsultationRequest> _pendingRequests = [];
  List<dynamic> _messages = []; // Will define a Message model later
  List<Map<String, dynamic>> _completedNotes = [];

  // Getters
  List<ConsultationRequest> get urgentRequests => _urgentRequests;
  List<ConsultationRequest> get scheduledRequests => _scheduledRequests;
  List<ConsultationRequest> get pendingRequests => _pendingRequests;
  List<dynamic> get messages => _messages;
  List<Map<String, dynamic>> get completedNotes => _completedNotes;

  // Selected patient data
  UserModel? selectedPatient;
  ConsultationRequest? selectedRequest;
  String? selectedTriageSummary;

  // Dashboard state
  bool isLoading = false;
  String? errorMessage;

  // Initialize provider data
  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();

    try {
      // Get current provider data
      final String providerId = _auth.currentUser?.uid ?? '';
      if (providerId.isEmpty) {
        throw Exception('Not authenticated');
      }

      // Get provider profile
      final providerDoc =
          await _firestore.collection('users').doc(providerId).get();
      if (!providerDoc.exists) {
        throw Exception('Provider profile not found');
      }

      // Set provider data
      currentProvider = UserModel.fromMap(
        providerDoc.data() as Map<String, dynamic>,
      );

      // Load dashboard data
      await Future.wait([
        _fetchConsultations(),
        _fetchMessages(),
        _fetchCompletedNotes(),
      ]);

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = 'Error initializing dashboard: $e';
      debugPrint(errorMessage);
      notifyListeners();
    }
  }

  // Fetch all types of consultations
  Future<void> _fetchConsultations() async {
    try {
      // Get all consultations
      final querySnapshot =
          await _firestore
              .collection('conversations')
              .orderBy('createdAt', descending: true)
              .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('No consultations found');
        return;
      }

      debugPrint('Found ${querySnapshot.docs.length} consultations');

      // Process all consultations and sort them by type
      _urgentRequests = [];
      _scheduledRequests = [];
      _pendingRequests = [];

      for (var doc in querySnapshot.docs) {
        final consultation = ConsultationRequest.fromFirestore(doc);

        // Sort consultations by type and status
        if (consultation.status.toLowerCase() == 'scheduled' ||
            consultation.status.toLowerCase() == 'checkedin' ||
            consultation.status.toLowerCase() == 'inprogress') {
          _scheduledRequests.add(consultation);
        } else if (consultation.urgency.toLowerCase() == 'urgent' ||
            consultation.urgency.toLowerCase() == 'quick') {
          _urgentRequests.add(consultation);
        } else if (consultation.status.toLowerCase() == 'pending' ||
            consultation.status.toLowerCase() == 'triaged') {
          _pendingRequests.add(consultation);
        }
      }

      // Sort scheduled appointments by date/time
      _scheduledRequests.sort((a, b) {
        if (a.scheduledDateTime == null && b.scheduledDateTime == null)
          return 0;
        if (a.scheduledDateTime == null) return 1;
        if (b.scheduledDateTime == null) return -1;
        return a.scheduledDateTime!.compareTo(b.scheduledDateTime!);
      });

      debugPrint('Urgent requests: ${_urgentRequests.length}');
      debugPrint('Scheduled requests: ${_scheduledRequests.length}');
      debugPrint('Pending requests: ${_pendingRequests.length}');
    } catch (e) {
      debugPrint('Error fetching consultations: $e');
    }
  }

  // Fetch messages (placeholder)
  Future<void> _fetchMessages() async {
    // Placeholder - to be implemented
    _messages = [];
  }

  // Fetch completed notes (placeholder)
  Future<void> _fetchCompletedNotes() async {
    // Placeholder - to be implemented
    _completedNotes = [];
  }

  // Select a patient to view details
  Future<void> selectPatient(String patientId, String requestId) async {
    isLoading = true;
    notifyListeners();

    try {
      // Load patient data
      final patientDoc =
          await _firestore.collection('users').doc(patientId).get();
      if (!patientDoc.exists) {
        throw Exception('Patient not found');
      }

      // Set selected patient
      selectedPatient = UserModel.fromMap(
        patientDoc.data() as Map<String, dynamic>,
      );

      // Load consultation data
      final requestDoc =
          await _firestore.collection('conversations').doc(requestId).get();
      if (!requestDoc.exists) {
        throw Exception('Consultation not found');
      }

      // Set selected request
      selectedRequest = ConsultationRequest.fromFirestore(requestDoc);

      // Set triage summary directly from the consultation
      selectedTriageSummary = selectedRequest?.aiTriageSummary;

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = 'Error loading patient details: $e';
      debugPrint(errorMessage);
      notifyListeners();
    }
  }

  // Clear selected patient
  void clearSelectedPatient() {
    selectedPatient = null;
    selectedRequest = null;
    selectedTriageSummary = null;
    notifyListeners();
  }

  // Start a video call
  Future<void> startVideoCall() async {
    // To be implemented
    notifyListeners();
  }

  // Refresh dashboard data
  Future<void> refreshDashboard() async {
    isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _fetchConsultations(),
        _fetchMessages(),
        _fetchCompletedNotes(),
      ]);

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = 'Error refreshing dashboard: $e';
      debugPrint(errorMessage);
      notifyListeners();
    }
  }
}
