// lib/screens/consultation/final_screen.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../models/patient_request.dart';
import '../../providers/provider_provider.dart';
import '../../providers/request_provider.dart';
import '../../theme.dart';
import '../video_call/video_call_home_screen.dart'; // Add import for VideoCallHomeScreen
import '../../screens/main_screen.dart';

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
              // Animated success icon with improved container styling
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.successColor.withOpacity(0.1),
                      AppTheme.backgroundColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.successColor.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Lottie.asset(
                    'assets/animations/doctor_connected.json',
                    width: 200,
                    height: 200,
                    repeat: true,
                    frameRate: FrameRate.max,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Message container with improved styling
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  finalMessage,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              // Primary action button with improved styling
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(
                    isSynchronous ? Icons.video_call : Icons.message,
                    size: 24,
                  ),
                  label: Text(buttonText),
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
                        MaterialPageRoute(builder: (_) => const MainScreen()),
                        (route) => false,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isSynchronous
                            ? AppTheme.successColor
                            : AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              // Alternative action - return home
              if (isSynchronous)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextButton.icon(
                    icon: const Icon(Icons.home_outlined),
                    label: const Text("Return to Home"),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const MainScreen()),
                        (route) => false,
                      );
                    },
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
