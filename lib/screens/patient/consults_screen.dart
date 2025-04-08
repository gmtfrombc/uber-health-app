import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/medical_questions_provider.dart';
import '../../models/patient_request.dart';
import '../../models/chat_mode.dart';
import '../../services/firebase_service.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/consistent_app_bar.dart';
import 'category_selection_screen.dart';
import 'scheduling_screen.dart';
import 'medical_question_details_screen.dart';
import 'request_screen.dart';

class ConsultsScreen extends StatefulWidget {
  const ConsultsScreen({super.key});

  @override
  State<ConsultsScreen> createState() => _ConsultsScreenState();
}

class _ConsultsScreenState extends State<ConsultsScreen>
    with WidgetsBindingObserver {
  final FirebaseService _firebaseService = FirebaseService();
  bool _checkedAppointments = false;

  @override
  void initState() {
    super.initState();
    // Register observer to detect when the screen becomes visible
    WidgetsBinding.instance.addObserver(this);

    // Load data when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh data when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _initializeProviders();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeProviders() async {
    // Store providers before async operation
    final appointmentProvider = Provider.of<AppointmentProvider>(
      context,
      listen: false,
    );
    final medicalQuestionsProvider = Provider.of<MedicalQuestionsProvider>(
      context,
      listen: false,
    );

    // Perform async operations
    await appointmentProvider.refreshAppointments();
    await medicalQuestionsProvider.refreshQuestions();

    // Check if widget is still mounted before continuing
    if (!mounted) return;

    // Check for upcoming appointments
    if (!_checkedAppointments) {
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
    // Store provider and messenger before async operation
    final appointmentProvider = Provider.of<AppointmentProvider>(
      context,
      listen: false,
    );
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Perform async operation
      final success = await appointmentProvider.cancelAppointment(appointment);

      // Check if widget is still mounted before continuing
      if (!mounted) return;

      // Use stored messenger instead of context after async operation
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Appointment cancelled successfully'
                : 'Error cancelling appointment',
          ),
        ),
      );
    } catch (e) {
      // Check if widget is still mounted before continuing
      if (!mounted) return;

      // Use stored messenger instead of context after async operation
      messenger.showSnackBar(
        SnackBar(content: Text('Error cancelling appointment: $e')),
      );
    }
  }

  // Handle appointment rescheduling
  Future<void> _rescheduleAppointment(PatientRequest appointment) async {
    // Store navigator before async operation
    final navigator = Navigator.of(context);

    try {
      // No longer cancelling the appointment here - we'll do that only if user confirms reschedule

      // Check if widget is still mounted before continuing
      if (!mounted) return;

      // Use stored navigator instead of context after async operation
      // Now passing the appointmentId to know which appointment to update if rescheduled
      navigator.push(
        MaterialPageRoute(
          builder:
              (_) => SchedulingScreen(
                category: appointment.category,
                isUrgent: appointment.urgency.toLowerCase() == 'urgent',
                selectedProvider: null,
                appointmentId:
                    appointment.id, // Pass the appointment ID for reschedule
              ),
        ),
      );
    } catch (e) {
      // Check if widget is still mounted before continuing
      if (!mounted) return;

      // Use stored messenger
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error starting reschedule: $e')));
    }
  }

  // Handle appointment check-in
  Future<void> _checkInForAppointment(PatientRequest appointment) async {
    // Store navigator before async operation
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Perform async operation
      await _firebaseService.updateAppointmentStatus(
        appointment.id,
        RequestStatus.checkedIn,
      );

      // Check if widget is still mounted before continuing
      if (!mounted) return;

      // Use stored navigator instead of context after async operation
      navigator.push(
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
    } catch (e) {
      // Check if widget is still mounted before continuing
      if (!mounted) return;

      // Use stored messenger instead of context after async operation
      messenger.showSnackBar(SnackBar(content: Text('Error checking in: $e')));
    }
  }

  void _openMedicalQuestion(MedicalQuestion question) async {
    // Store provider and navigator before async operation
    final questionsProvider = Provider.of<MedicalQuestionsProvider>(
      context,
      listen: false,
    );
    final navigator = Navigator.of(context);

    // Perform async operation
    final result = await navigator.push(
      MaterialPageRoute(
        builder:
            (context) => MedicalQuestionDetailsScreen(questionId: question.id),
      ),
    );

    // Check if widget is still mounted before continuing
    if (!mounted) return;

    // If the result is true, the question was marked as done
    // or some other action was taken that requires refreshing
    if (result == true) {
      // Refresh to make sure our UI is updated after the operation
      questionsProvider.refreshQuestions();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Refresh data when tab is selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });

    return Scaffold(
      appBar: const ConsistentAppBar(title: 'Consults & Questions'),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Main content with RefreshIndicator
          RefreshIndicator(
            onRefresh: () async {
              await _initializeProviders();
            },
            child: ListView(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 96.0,
              ), // Extra bottom padding for button
              children: [
                _buildSectionTitle(context, 'Upcoming Appointments'),
                _buildEnhancedAppointmentList(context),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Medical Questions'),
                _buildEnhancedMedicalQuestionList(context),
              ],
            ),
          ),

          // Fixed position button at the bottom
          Positioned(
            left: 16.0,
            right: 16.0,
            bottom: 24.0, // Padding above bottom nav bar
            child: ElevatedButton.icon(
              icon: const Icon(Icons.medical_services_outlined),
              label: const Text('Request a Consult or Ask a Question'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RequestScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 4, // Add shadow for better visibility
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEnhancedAppointmentList(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Consumer<AppointmentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error.isNotEmpty) {
          return Center(child: Text('Error: ${provider.error}'));
        }
        if (provider.upcomingAppointments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                "No upcoming appointments",
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.grey[400] : Colors.black54,
                ),
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Consumer<MedicalQuestionsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final pendingQuestions = provider.pendingQuestions;
        final answeredQuestions = provider.answeredQuestions;
        final allQuestions = [...pendingQuestions, ...answeredQuestions];

        if (allQuestions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                "No medical questions",
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.grey[400] : Colors.black54,
                ),
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
    final isDarkMode = theme.brightness == Brightness.dark;

    // Truncate question text if too long
    final displayText =
        question.question.length > 60
            ? '${question.question.substring(0, 60)}...'
            : question.question;

    // Format the date
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedDate = dateFormat.format(question.timestamp);

    final isPending = question.status == 'pending';

    // Theme-aware colors
    final statusColor = isPending ? Colors.orange : Colors.green;

    final statusBgColor =
        isPending
            ? (isDarkMode
                ? Colors.orange.shade900.withOpacity(0.3)
                : Colors.orange.shade100)
            : (isDarkMode
                ? Colors.green.shade900.withOpacity(0.3)
                : Colors.green.shade100);

    final statusTextColor =
        isPending
            ? (isDarkMode ? Colors.orange.shade300 : Colors.orange.shade800)
            : (isDarkMode ? Colors.green.shade300 : Colors.green.shade800);

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: theme.dividerColor.withAlpha(51), width: 1),
      ),
      elevation: 1,
      color: isDarkMode ? theme.cardColor : Colors.white,
      child: InkWell(
        onTap: () {
          debugPrint('Navigating to question details for id: ${question.id}');
          _openMedicalQuestion(question);
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
                  color: statusColor,
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
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isPending ? 'Pending' : 'Answered',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusTextColor,
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
