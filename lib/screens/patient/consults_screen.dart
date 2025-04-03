import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/medical_questions_provider.dart';
import '../../models/patient_request.dart';
import '../../models/chat_mode.dart';
import '../../services/firebase_service.dart';
import '../../widgets/appointment_card.dart';
import '../../theme.dart';
import 'category_selection_screen.dart';
import 'scheduling_screen.dart';
import 'medical_question_details_screen.dart';
import 'request_screen.dart';

class ConsultsScreen extends StatefulWidget {
  const ConsultsScreen({super.key});

  @override
  State<ConsultsScreen> createState() => _ConsultsScreenState();
}

class _ConsultsScreenState extends State<ConsultsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _checkedAppointments = false;

  @override
  void initState() {
    super.initState();
    // Load data when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  Future<void> _initializeProviders() async {
    // Get appointment provider and refresh data
    final appointmentProvider = Provider.of<AppointmentProvider>(
      context,
      listen: false,
    );
    await appointmentProvider.refreshAppointments();

    // Also refresh medical questions
    final medicalQuestionsProvider = Provider.of<MedicalQuestionsProvider>(
      context,
      listen: false,
    );
    await medicalQuestionsProvider.refreshQuestions();

    // Check for upcoming appointments
    if (!_checkedAppointments && mounted) {
      appointmentProvider.showAppointmentNotification((appointment) {
        if (mounted) {
          _showAppointmentCheckInDialog(appointment);
        }
      });
      _checkedAppointments = true;
    }
  }

  // Show the check-in dialog
  void _showAppointmentCheckInDialog(PatientRequest appointment) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final appointmentDate = dateFormat.format(appointment.scheduledDateTime!);
    final appointmentTime = timeFormat.format(appointment.scheduledDateTime!);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Your appointment is approaching!'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('You have a scheduled appointment on:'),
                const SizedBox(height: 8),
                Text(
                  '$appointmentDate at $appointmentTime',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text('Please select an option:'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel Appointment'),
              onPressed: () {
                Navigator.of(context).pop();
                _cancelAppointment(appointment);
              },
            ),
            TextButton(
              child: const Text('Reschedule'),
              onPressed: () {
                Navigator.of(context).pop();
                _rescheduleAppointment(appointment);
              },
            ),
            ElevatedButton(
              child: const Text('Check In Now'),
              onPressed: () {
                Navigator.of(context).pop();
                _checkInForAppointment(appointment);
              },
            ),
          ],
        );
      },
    );
  }

  // Handle appointment cancellation
  Future<void> _cancelAppointment(PatientRequest appointment) async {
    try {
      // Use AppointmentProvider to cancel appointment
      final appointmentProvider = Provider.of<AppointmentProvider>(
        context,
        listen: false,
      );
      final success = await appointmentProvider.cancelAppointment(appointment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Appointment cancelled successfully'
                  : 'Error cancelling appointment',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling appointment: $e')),
        );
      }
    }
  }

  // Handle appointment rescheduling
  Future<void> _rescheduleAppointment(PatientRequest appointment) async {
    try {
      // First cancel the current appointment
      await _firebaseService.updateAppointmentStatus(
        appointment.id,
        RequestStatus.cancelled,
      );

      if (mounted) {
        // Navigate to scheduling screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => SchedulingScreen(
                  category: appointment.category,
                  isUrgent: appointment.urgency.toLowerCase() == 'urgent',
                  selectedProvider: null, // We don't have provider info here
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rescheduling appointment: $e')),
        );
      }
    }
  }

  // Handle appointment check-in
  Future<void> _checkInForAppointment(PatientRequest appointment) async {
    try {
      // Update status to checked in
      await _firebaseService.updateAppointmentStatus(
        appointment.id,
        RequestStatus.checkedIn,
      );

      if (mounted) {
        // Navigate to category selection screen first to ensure consistent flow
        // This will allow the AI prompt to be based on the selected category
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => CategorySelectionScreen(
                  urgency: appointment.urgency,
                  chatMode:
                      ChatMode
                          .immediate, // Add a new mode to indicate immediate start
                  appointmentId:
                      appointment.id, // Pass the appointment ID for context
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error checking in: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consults & Questions')),
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await _initializeProviders();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Add request button at the top
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.medical_services_outlined),
                label: const Text('Request a Consult or Ask Question'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RequestScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _buildSectionTitle(context, 'Upcoming Appointments'),
            _buildEnhancedAppointmentList(context),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Medical Questions'),
            _buildEnhancedMedicalQuestionList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEnhancedAppointmentList(BuildContext context) {
    return Consumer<AppointmentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error.isNotEmpty) {
          return Center(child: Text('Error: ${provider.error}'));
        }
        if (provider.upcomingAppointments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                "No upcoming appointments",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.upcomingAppointments.length,
          itemBuilder: (context, index) {
            final appointment = provider.upcomingAppointments[index];

            return AppointmentCard(
              appointment: appointment,
              onCancel: _cancelAppointment,
              onReschedule: _rescheduleAppointment,
              onCheckIn: _checkInForAppointment,
            );
          },
        );
      },
    );
  }

  Widget _buildEnhancedMedicalQuestionList(BuildContext context) {
    return Consumer<MedicalQuestionsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final pendingQuestions = provider.pendingQuestions;
        final answeredQuestions = provider.answeredQuestions;
        final allQuestions = [...pendingQuestions, ...answeredQuestions];

        if (allQuestions.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                "No medical questions",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allQuestions.length,
          itemBuilder: (context, index) {
            final question = allQuestions[index];
            return _buildQuestionItem(question);
          },
        );
      },
    );
  }

  Widget _buildQuestionItem(MedicalQuestion question) {
    final theme = Theme.of(context);

    // Truncate question text if too long
    final displayText =
        question.question.length > 60
            ? '${question.question.substring(0, 60)}...'
            : question.question;

    // Format the date
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedDate = dateFormat.format(question.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: AppTheme.textTertiaryColor.withAlpha(51),
          width: 1,
        ),
      ),
      elevation: 1,
      child: InkWell(
        onTap: () async {
          debugPrint('Navigating to question details for id: ${question.id}');
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => MedicalQuestionDetailsScreen(questionId: question.id),
            ),
          );

          // Refresh questions when returning
          if (mounted) {
            await Provider.of<MedicalQuestionsProvider>(
              context,
              listen: false,
            ).refreshQuestions();
          }
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4, right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      question.status == 'pending'
                          ? Colors.orange
                          : Colors.green,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayText,
                      style: theme.textTheme.bodyLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(formattedDate, style: theme.textTheme.bodySmall),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                question.status == 'pending'
                                    ? Colors.orange.shade100
                                    : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            question.status == 'pending'
                                ? 'Pending'
                                : 'Answered',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color:
                                  question.status == 'pending'
                                      ? Colors.orange.shade800
                                      : Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.primary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
