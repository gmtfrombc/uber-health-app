// lib/screens/patient/scheduling_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/request_provider.dart';
import '../../models/patient_request.dart';
import '../../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme.dart';
import 'home_screen.dart';
import '../../models/provider_model.dart';

class SchedulingScreen extends StatefulWidget {
  final String category;
  final bool isUrgent;
  final ProviderModel? selectedProvider;

  const SchedulingScreen({
    super.key,
    required this.category,
    required this.isUrgent,
    this.selectedProvider,
  });

  @override
  State<SchedulingScreen> createState() => _SchedulingScreenState();
}

class _SchedulingScreenState extends State<SchedulingScreen> {
  late DateTime scheduledDateTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Set the default scheduled time to one hour later, rounded to the next 15-minute interval.
    scheduledDateTime = _getRoundedTime(
      DateTime.now().add(const Duration(hours: 1)),
    );
  }

  // Helper function to round a DateTime to the next 15-minute interval.
  DateTime _getRoundedTime(DateTime dt) {
    int minute = dt.minute;
    int mod = minute % 15;
    if (mod != 0) {
      // Subtract the remainder and add 15 minutes to get to the next interval.
      dt = dt.subtract(Duration(minutes: mod)).add(const Duration(minutes: 15));
    }
    return dt;
  }

  Future<void> _saveScheduledAppointment() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final requestProvider = Provider.of<RequestProvider>(
        context,
        listen: false,
      );
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to schedule an appointment'),
          ),
        );
        return;
      }

      // Debug logging for provider ID
      if (widget.selectedProvider != null) {
        debugPrint(
          'Using selected provider: ${widget.selectedProvider!.id}, ${widget.selectedProvider!.fullName}',
        );
      } else {
        debugPrint('No provider selected in scheduling screen');
      }

      if (requestProvider.currentRequest != null) {
        debugPrint(
          'Current request provider ID: ${requestProvider.currentRequest!.providerId}',
        );
      }

      // Create the appointment request
      final request =
          requestProvider.currentRequest?.copyWith(
            status: RequestStatus.scheduled,
            scheduledDateTime: scheduledDateTime,
          ) ??
          PatientRequest(
            patientId: userId,
            requestType: RequestType.consult,
            urgency: widget.isUrgent ? 'Urgent' : 'Routine',
            category: widget.category,
            providerType: requestProvider.providerType,
            status: RequestStatus.scheduled,
            scheduledDateTime: scheduledDateTime,
            providerId: widget.selectedProvider?.id,
          );

      debugPrint('Final request provider ID: ${request.providerId}');

      // Save to Firestore
      final conversationId = await FirebaseService().savePatientRequest(
        request,
        [], // Empty conversation array since no AI triage yet
        status: RequestStatus.scheduled.name,
      );

      if (conversationId == null) {
        throw Exception('Failed to save appointment to database');
      }

      // Store the appointment ID in the provider for reference
      requestProvider.lastConversationId = conversationId;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment scheduled successfully')),
        );

        // Navigate to home screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scheduling appointment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Schedule Your Consult')),
      body: Column(
        children: [
          Expanded(
            child: CupertinoDatePicker(
              initialDateTime: scheduledDateTime,
              mode: CupertinoDatePickerMode.dateAndTime,
              minuteInterval: 15,
              onDateTimeChanged: (newDateTime) {
                setState(() {
                  scheduledDateTime = newDateTime;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _saveScheduledAppointment,
              child:
                  _isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text('Confirm Appointment'),
            ),
          ),
        ],
      ),
    );
  }
}
