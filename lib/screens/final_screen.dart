// lib/screens/final_screen.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'home_screen.dart'; // Import HomeScreen
import '../services/firebase_service.dart';
import '../models/patient_request.dart';

class FinalScreen extends StatelessWidget {
  final bool isSynchronous;
  final String? appointmentId;

  const FinalScreen({
    required this.isSynchronous,
    this.appointmentId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    String finalMessage;
    String buttonText;

    if (appointmentId != null) {
      finalMessage = 'Your appointment check-in is complete';
      buttonText = 'Return to Home';

      // Update appointment status to inProgress
      _updateAppointmentStatus(appointmentId!, RequestStatus.inProgress);
    } else if (isSynchronous) {
      finalMessage = 'You are connected to Dr. Tolson';
      buttonText = 'Start Consultation';
    } else {
      finalMessage = 'Dr. Tolson has responded to your message';
      buttonText = 'Read Message';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Connected')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/doctor_connected.json',
              width: 200,
              height: 200,
              repeat: true,
            ),
            const SizedBox(height: 20),
            Text(
              finalMessage,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to update appointment status
  Future<void> _updateAppointmentStatus(
    String appointmentId,
    RequestStatus status,
  ) async {
    try {
      final firebaseService = FirebaseService();
      await firebaseService.updateAppointmentStatus(appointmentId, status);
    } catch (e) {
      debugPrint('Error updating appointment status: $e');
    }
  }
}
