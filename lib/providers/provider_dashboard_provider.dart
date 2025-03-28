import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/patient_request.dart';
import '../models/triage_summary.dart';

class ProviderDashboardProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Provider data
  UserModel? currentProvider;

  // Dashboard data
  List<PatientRequest> _urgentRequests = [];
  List<PatientRequest> _scheduledRequests = [];
  List<dynamic> _messages = []; // Will define a Message model later
  List<Map<String, dynamic>> _completedNotes = [];

  // Getters
  List<PatientRequest> get urgentRequests => _urgentRequests;
  List<PatientRequest> get scheduledRequests => _scheduledRequests;
  List<dynamic> get messages => _messages;
  List<Map<String, dynamic>> get completedNotes => _completedNotes;

  // Selected patient data
  UserModel? selectedPatient;
  PatientRequest? selectedRequest;
  TriageSummary? selectedTriageSummary;

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
        _fetchUrgentRequests(),
        _fetchScheduledRequests(),
        _fetchMessages(),
        _fetchCompletedNotes(),
      ]);

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = 'Error initializing dashboard: $e';
      notifyListeners();
    }
  }

  // Fetch urgent patient requests
  Future<void> _fetchUrgentRequests() async {
    try {
      final querySnapshot =
          await _firestore
              .collection('patientRequests')
              .where('urgency', isEqualTo: 'Urgent')
              .where('status', isEqualTo: RequestStatus.triaged.name)
              .orderBy('timestamp', descending: true)
              .limit(10)
              .get();

      _urgentRequests =
          querySnapshot.docs
              .map((doc) => PatientRequest.fromMap(doc.data(), docId: doc.id))
              .toList();
    } catch (e) {
      debugPrint('Error fetching urgent requests: $e');
    }
  }

  // Fetch scheduled requests
  Future<void> _fetchScheduledRequests() async {
    try {
      final querySnapshot =
          await _firestore
              .collection('patientRequests')
              .where('status', isEqualTo: RequestStatus.assigned.name)
              .where('assignedProviderId', isEqualTo: _auth.currentUser?.uid)
              .orderBy('timestamp', descending: true)
              .get();

      _scheduledRequests =
          querySnapshot.docs
              .map((doc) => PatientRequest.fromMap(doc.data(), docId: doc.id))
              .toList();
    } catch (e) {
      debugPrint('Error fetching scheduled requests: $e');
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

      // Load request data
      final requestDoc =
          await _firestore.collection('patientRequests').doc(requestId).get();
      if (!requestDoc.exists) {
        throw Exception('Request not found');
      }

      // Set selected request
      selectedRequest = PatientRequest.fromMap(
        requestDoc.data() as Map<String, dynamic>,
        docId: requestDoc.id,
      );

      // Load triage summary if available
      if (selectedRequest?.triageSummaryId != null) {
        final summaryDoc =
            await _firestore
                .collection('triageSummaries')
                .doc(selectedRequest!.triageSummaryId)
                .get();

        if (summaryDoc.exists) {
          selectedTriageSummary = TriageSummary.fromMap(
            summaryDoc.data() as Map<String, dynamic>,
            docId: summaryDoc.id,
          );
        }
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = 'Error loading patient details: $e';
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
        _fetchUrgentRequests(),
        _fetchScheduledRequests(),
        _fetchMessages(),
        _fetchCompletedNotes(),
      ]);

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = 'Error refreshing dashboard: $e';
      notifyListeners();
    }
  }
}
