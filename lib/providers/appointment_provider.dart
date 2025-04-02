import 'package:flutter/material.dart';
import '../models/patient_request.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<PatientRequest> _upcomingAppointments = [];
  final List<PatientRequest> _pastAppointments = [];
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<PatientRequest> get upcomingAppointments => _upcomingAppointments;
  List<PatientRequest> get pastAppointments => _pastAppointments;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Initialize provider and load appointments
  Future<void> initialize() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await refreshAppointments();
    }
  }

  // Refresh appointments from Firebase
  Future<void> refreshAppointments() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Fetch upcoming appointments
      _upcomingAppointments = await _firebaseService.getUpcomingAppointments(
        userId,
      );

      // TODO: Implement past appointments fetching if needed
      // _pastAppointments = await _firebaseService.getPastAppointments(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load appointments: $e';
      notifyListeners();
    }
  }

  // Cancel an appointment
  Future<bool> cancelAppointment(PatientRequest appointment) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _firebaseService.updateAppointmentStatus(
        appointment.id,
        RequestStatus.cancelled,
      );

      if (success) {
        // Remove the cancelled appointment from the list
        _upcomingAppointments.removeWhere((appt) => appt.id == appointment.id);
        notifyListeners();
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to cancel appointment: $e';
      notifyListeners();
      return false;
    }
  }

  // Get next appointment (the first upcoming one)
  PatientRequest? getNextAppointment() {
    if (_upcomingAppointments.isEmpty) return null;
    return _upcomingAppointments.first;
  }

  // Check for immediate appointments (within 15 minutes)
  Future<PatientRequest?> checkForImmediateAppointments() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) return null;

    try {
      final immediateAppointments = await _firebaseService
          .getImmediateAppointments(userId);
      return immediateAppointments.isNotEmpty
          ? immediateAppointments.first
          : null;
    } catch (e) {
      debugPrint('Error checking immediate appointments: $e');
      return null;
    }
  }

  // Add a method to handle appointment notifications safely (to be called from a mounted widget)
  void showAppointmentNotification(Function(PatientRequest) showDialog) {
    // Check if there's an immediate appointment that needs attention
    checkForImmediateAppointments().then((appointment) {
      if (appointment != null) {
        showDialog(appointment);
      }
    });
  }
}
