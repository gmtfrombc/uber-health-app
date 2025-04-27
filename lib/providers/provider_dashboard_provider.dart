import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
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
  String? successMessage;

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

      final now = DateTime.now();

      for (var doc in querySnapshot.docs) {
        final consultation = ConsultationRequest.fromFirestore(doc);

        // Debug log for medical questions
        if (consultation.requestType.toLowerCase() == 'medicalquestion') {
          debugPrint(
            'Found medical question with ID: ${doc.id}, status: ${consultation.status}',
          );
        }

        // Skip any consultations with status 'cancelled' or 'resolved'
        if (consultation.status.toLowerCase() == 'cancelled' ||
            consultation.status.toLowerCase() == 'resolved') {
          debugPrint('Skipping cancelled/resolved consultation: ${doc.id}');
          continue;
        }

        // Check if scheduled appointment is expired (past the scheduled time)
        if (consultation.status.toLowerCase() == 'scheduled' &&
            consultation.scheduledDateTime != null &&
            consultation.scheduledDateTime!.isBefore(now)) {
          // Auto-cancel expired appointments
          await _firestore.collection('conversations').doc(doc.id).update({
            'status': 'cancelled',
            'updatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint('Auto-cancelled expired appointment: ${doc.id}');
          continue; // Skip adding this to any list
        }

        // Sort consultations by type and status
        if (consultation.status.toLowerCase() == 'scheduled' ||
            consultation.status.toLowerCase() == 'checkedin' ||
            consultation.status.toLowerCase() == 'inprogress') {
          _scheduledRequests.add(consultation);
        } else if (consultation.urgency.toLowerCase() == 'urgent' ||
            consultation.urgency.toLowerCase() == 'quick') {
          _urgentRequests.add(consultation);
        } else if (consultation.status.toLowerCase() == 'pending' ||
            consultation.status.toLowerCase() == 'triaged' ||
            consultation.requestType.toLowerCase() == 'medicalquestion') {
          // Add medical questions to pending requests
          _pendingRequests.add(consultation);
        }
      }

      // Sort scheduled appointments by date/time
      _scheduledRequests.sort((a, b) {
        if (a.scheduledDateTime == null && b.scheduledDateTime == null) {
          return 0;
        }
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
    clearMessages(); // Clear any success or error messages when selecting a patient
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
    // Implemented - navigates to video call screen
    if (selectedPatient == null) {
      errorMessage = 'Please select a patient first';
      notifyListeners();
      return;
    }

    // We'll use this method from the dashboard screen to navigate to the video call
    notifyListeners();
  }

  // Method to refresh all dashboard data
  Future<void> refreshDashboard() async {
    isLoading = true;
    errorMessage = null;
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

  // Method to delete a consultation
  Future<bool> deleteConsultation(String consultationId) async {
    try {
      // Clear any messages from previous operations
      clearMessages();

      // First update in Firebase - do this BEFORE updating local state
      await _firestore.collection('conversations').doc(consultationId).update({
        'status': 'cancelled',
        'deletedBy': 'provider',
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Firebase update succeeded, now update local state
      _updateLocalListsAfterDeletion(consultationId);

      // Set success message
      successMessage = 'Consultation removed successfully';

      // Clear selection if the deleted consultation was selected
      if (selectedRequest?.id == consultationId) {
        clearSelectedPatient();
      }

      // Notify of the changes
      notifyListeners();

      // Log success for debugging
      debugPrint(
        'Consultation $consultationId successfully marked as cancelled in Firebase',
      );

      return true;
    } catch (e) {
      // Log the detailed error for debugging
      debugPrint('Error deleting consultation $consultationId: $e');
      errorMessage = 'Error deleting consultation: $e';
      notifyListeners();
      return false;
    }
  }

  // Helper to update the local lists when a consultation is deleted
  void _updateLocalListsAfterDeletion(String consultationId) {
    // Remove from all lists to ensure it's gone regardless of which list it was in
    _urgentRequests.removeWhere((req) => req.id == consultationId);
    _scheduledRequests.removeWhere((req) => req.id == consultationId);
    _pendingRequests.removeWhere((req) => req.id == consultationId);
  }

  // Clear messages
  void clearMessages() {
    errorMessage = null;
    successMessage = null;
  }

  // Debug method to check a consultation's status in Firebase
  Future<void> checkConsultationStatus(String consultationId) async {
    try {
      final doc =
          await _firestore
              .collection('conversations')
              .doc(consultationId)
              .get();
      if (!doc.exists) {
        debugPrint('Consultation $consultationId does not exist in Firebase');
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      debugPrint('Consultation $consultationId status: ${data['status']}');
      debugPrint(
        'Consultation details: ${data.toString().substring(0, min(100, data.toString().length))}...',
      );
    } catch (e) {
      debugPrint('Error checking consultation $consultationId: $e');
    }
  }

  // Method to actually refresh from server - this clears local lists and refetches everything
  Future<void> refreshFromServer() async {
    isLoading = true;
    clearMessages();
    notifyListeners();

    try {
      // Clear all local lists to ensure we get fresh data
      _urgentRequests = [];
      _scheduledRequests = [];
      _pendingRequests = [];

      debugPrint('Refreshing data from server...');

      // Fetch fresh data from server
      await Future.wait([
        _fetchConsultations(),
        _fetchMessages(),
        _fetchCompletedNotes(),
      ]);

      isLoading = false;
      successMessage = 'Dashboard refreshed from server';
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = 'Error refreshing from server: $e';
      debugPrint(errorMessage);
      notifyListeners();
    }
  }
}
