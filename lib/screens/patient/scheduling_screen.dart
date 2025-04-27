// lib/screens/patient/scheduling_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/request_provider.dart';
import '../../models/patient_request.dart';
import '../../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/provider_model.dart';
import '../../widgets/consistent_app_bar.dart';

class SchedulingScreen extends StatefulWidget {
  final String category;
  final bool isUrgent;
  final ProviderModel? selectedProvider;
  final String? appointmentId; // Add appointment ID for reschedule operation

  const SchedulingScreen({
    super.key,
    required this.category,
    required this.isUrgent,
    this.selectedProvider,
    this.appointmentId, // Add this parameter
  });

  @override
  State<SchedulingScreen> createState() => _SchedulingScreenState();
}

class _SchedulingScreenState extends State<SchedulingScreen> {
  late DateTime scheduledDateTime;
  bool _isSubmitting = false;
  bool _isRescheduling =
      false; // Track if we're rescheduling an existing appointment
  final DateTime _minimumDate = DateTime.now().add(const Duration(minutes: 30));

  @override
  void initState() {
    super.initState();
    // Set the default scheduled time to one hour later, rounded to the next 15-minute interval.
    scheduledDateTime = _getRoundedTime(
      DateTime.now().add(const Duration(hours: 1)),
    );

    // Determine if we're rescheduling
    _isRescheduling = widget.appointmentId != null;

    if (_isRescheduling) {
      debugPrint('Rescheduling appointment ID: ${widget.appointmentId}');
    }
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

      PatientRequest? originalRequest;

      // If we're rescheduling, get the original request first so we can properly modify it
      if (_isRescheduling && widget.appointmentId != null) {
        originalRequest = await FirebaseService().getPatientRequestById(
          widget.appointmentId!,
        );
        if (originalRequest == null) {
          throw Exception('Original appointment not found');
        }
        debugPrint(
          'Original appointment found for reschedule: ${originalRequest.id}',
        );
      }

      // Create the appointment request
      final request =
          _isRescheduling && originalRequest != null
              ? originalRequest.copyWith(
                scheduledDateTime: scheduledDateTime,
                status: RequestStatus.scheduled,
              )
              : requestProvider.currentRequest?.copyWith(
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
          SnackBar(
            content: Text(
              _isRescheduling
                  ? 'Appointment rescheduled successfully'
                  : 'Appointment scheduled successfully',
            ),
          ),
        );

        // Navigate to main screen with bottom navigation instead of directly to HomeScreen
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/main', // Use the main route that has the bottom navigation
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
    final DateFormat dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final DateFormat timeFormat = DateFormat('h:mm a');
    final theme = Theme.of(context);
    return PopScope(
      // Block automatic pop so we can run custom logic first
      canPop: false,
      // Preferred callback in recent Flutter versions
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          // User tapped back – pop manually and pass `false`
          // to indicate no changes were made.
          Navigator.of(context).pop(false);
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: ConsistentAppBar(
          title:
              _isRescheduling
                  ? 'Reschedule Appointment'
                  : 'Schedule Your Consult',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Just navigate back without cancelling the appointment
              Navigator.of(context).pop(false);
            },
          ),
        ),
        body: Column(
          children: [
            // Header with selected date time info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isRescheduling
                            ? 'Reschedule Your Appointment'
                            : 'Your Appointment',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    dateFormat.format(scheduledDateTime),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'at ${timeFormat.format(scheduledDateTime)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(
                        (0.8 * 255).round(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    color: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.medical_services,
                            color: theme.colorScheme.onPrimary.withAlpha(230),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.category,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (widget.selectedProvider != null)
                                  Text(
                                    'with Dr. ${widget.selectedProvider!.lastname}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onPrimary
                                          .withAlpha(230),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  widget.isUrgent
                                      ? theme.colorScheme.error.withAlpha(77)
                                      : theme.colorScheme.tertiary.withAlpha(
                                        77,
                                      ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.isUrgent ? 'Urgent' : 'Routine',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Instructions
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 8.0),
              child: Text(
                'Select a date and time for your appointment',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Date picker with shadow
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 12.0),
                decoration: BoxDecoration(
                  color:
                      theme.brightness == Brightness.dark
                          ? theme.colorScheme.surface
                          : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          theme.brightness == Brightness.dark
                              ? Colors.black.withAlpha(50)
                              : Colors.black.withAlpha(25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness: theme.brightness,
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle:
                            theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ) ??
                            TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      initialDateTime: scheduledDateTime,
                      minimumDate: _minimumDate,
                      mode: CupertinoDatePickerMode.dateAndTime,
                      minuteInterval: 15,
                      backgroundColor: Colors.transparent,
                      onDateTimeChanged: (newDateTime) {
                        // Ensure the date is not in the past
                        if (newDateTime.isBefore(_minimumDate)) {
                          newDateTime = _minimumDate;
                        }
                        setState(() {
                          scheduledDateTime = newDateTime;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Confirm button
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 20.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _saveScheduledAppointment,
                  // Use the global theme's button style
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    disabledBackgroundColor: theme.colorScheme.primary
                        .withAlpha((0.6 * 255).round()),
                  ),
                  child:
                      _isSubmitting
                          ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.onPrimary,
                              strokeWidth: 3,
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                _isRescheduling
                                    ? 'Confirm Reschedule'
                                    : 'Confirm Appointment',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
