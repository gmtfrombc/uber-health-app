// lib/screens/consultation/final_screen.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../patient/home_screen.dart'; // Updated import path
import '../../services/firebase_service.dart';
import '../../models/patient_request.dart';
import '../../providers/provider_provider.dart';
import '../../providers/request_provider.dart';
import '../../theme.dart';
import '../video_call/video_call_home_screen.dart'; // Add import for VideoCallHomeScreen

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
    // Get provider info
    final providerProvider = Provider.of<ProviderProvider>(
      context,
      listen: false,
    );
    final requestProvider = Provider.of<RequestProvider>(
      context,
      listen: false,
    );
    final selectedProvider = providerProvider.selectedProvider;

    // Determine provider name format
    String providerName = "your provider";
    if (selectedProvider != null) {
      // Format as "Dr. LastName" if credentials include MD, otherwise "FirstName LastName, Credentials"
      if (selectedProvider.credentials?.toLowerCase().contains('md') == true) {
        providerName = "Dr. ${selectedProvider.lastname}";
      } else if (selectedProvider.credentials?.isNotEmpty == true) {
        providerName =
            "${selectedProvider.firstname} ${selectedProvider.lastname}, ${selectedProvider.credentials}";
      } else {
        providerName =
            "${selectedProvider.firstname} ${selectedProvider.lastname}";
      }
    } else if (requestProvider.currentRequest?.providerId != null) {
      // If we have a providerId in the request but no selected provider, use generic text
      providerName = "your assigned provider";
    }

    String finalMessage;
    String buttonText;

    if (appointmentId != null) {
      finalMessage = 'Your appointment check-in is complete';
      buttonText = 'Start Consultation';

      // Update appointment status to inProgress
      _updateAppointmentStatus(appointmentId!, RequestStatus.inProgress);
    } else if (isSynchronous) {
      finalMessage = 'You are connected to $providerName';
      buttonText = 'Start Consultation';
    } else {
      finalMessage = '$providerName has responded to your message';
      buttonText = 'Read Message';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connected'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Lottie.asset(
                  'assets/animations/doctor_connected.json',
                  width: 200,
                  height: 200,
                  repeat: true,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                finalMessage,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isSynchronous) {
                      // Navigate to video call screen for synchronous consultations
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VideoCallHomeScreen(),
                        ),
                        (route) => false,
                      );
                    } else {
                      // Return to home for all other cases
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
      // Using updatePatientRequest instead of updateAppointmentStatus
      await firebaseService.updatePatientRequest(appointmentId, {
        'status': status.name,
      });
    } catch (e) {
      debugPrint('Error updating appointment status: $e');
    }
  }
}
