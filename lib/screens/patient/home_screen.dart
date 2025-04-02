// lib/screens/patient/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'request_screen.dart';
import '../auth/profile_edit_screen.dart';
import '../../widgets/app_drawer.dart';
import '../../models/user_model.dart';
import '../../models/patient_request.dart';
import '../../models/chat_mode.dart';
import '../../services/firebase_service.dart';
import 'scheduling_screen.dart';
import 'category_selection_screen.dart';
import 'package:intl/intl.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/provider_data_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/medical_questions_provider.dart';
import 'medical_question_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _checkedAppointments = false;

  @override
  void initState() {
    super.initState();
    // Initialize providers and check for appointments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh medical questions data whenever the screen gains focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MedicalQuestionsProvider>(
        context,
        listen: false,
      ).refreshQuestions();
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    // Refresh when the app is hot reloaded
    debugPrint("HomeScreen reassembled - refreshing data");
    _initializeProviders();
  }

  // Initialize providers and check for appointments
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

    // Check for upcoming appointments using the safer method
    if (!_checkedAppointments && mounted) {
      appointmentProvider.showAppointmentNotification((appointment) {
        if (mounted) {
          _showAppointmentCheckInDialog(appointment);
        }
      });
      _checkedAppointments = true;
    }
  }

  Future<UserModel?> _fetchUser() async {
    // Use the UserProvider to get user profile
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isProfileLoaded) {
      await userProvider.fetchUserProfile();
    }
    return userProvider.userProfile;
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
          title: Text('Your appointment is approaching!'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('You have a scheduled appointment on:'),
                SizedBox(height: 8),
                Text(
                  '$appointmentDate at $appointmentTime',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text('Please select an option:'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel Appointment'),
              onPressed: () {
                Navigator.of(context).pop();
                _cancelAppointment(appointment);
              },
            ),
            TextButton(
              child: Text('Reschedule'),
              onPressed: () {
                Navigator.of(context).pop();
                _rescheduleAppointment(appointment);
              },
            ),
            ElevatedButton(
              child: Text('Check In Now'),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('XUBER Health')),
      endDrawer: const AppDrawer(),
      body: FutureBuilder<UserModel?>(
        future: _fetchUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No user data available."));
          }

          final user = snapshot.data!;
          // Extract first name from user.firstname (if available) or fallback.
          final firstName =
              user.firstname.trim().isNotEmpty ? user.firstname.trim() : '';
          final greeting =
              firstName.isEmpty ? "Welcome!" : "Welcome, $firstName!";

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header image.
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.asset(
                    'assets/images/welcome.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                  ),
                ),
                const SizedBox(height: 16),
                // Greeting text, centered horizontally.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    greeting,
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),

                // Upcoming Appointments Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildUpcomingAppointmentsCard(),
                ),

                const SizedBox(height: 16),

                // Medical Questions Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildMedicalQuestionsCard(),
                ),

                const SizedBox(height: 16),

                // Health Information Card with edit icon.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row with title and edit icon.
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.medical_information,
                                      size: 20,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        "Your Health Information",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge?.copyWith(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProfileEditScreen(),
                                    ),
                                  );
                                },
                                tooltip: "Edit Profile",
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildInfoSection("Medications:", user.medications),
                          const SizedBox(height: 16),
                          _buildInfoSection("Drug Allergies:", user.allergies),
                          const SizedBox(height: 16),
                          _buildInfoSection(
                            "Active Conditions:",
                            user.conditions,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Bottom buttons row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Row(
                    children: [
                      // Consult button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RequestScreen(),
                              ),
                            );
                          },
                          child: const Text('Request a New Consult'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper method to build an info section.
  Widget _buildInfoSection(String title, List<String>? items) {
    // Use UserProvider to format list with bullets
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          userProvider.formatListWithBullets(items),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  // Build the upcoming appointments card
  Widget _buildUpcomingAppointmentsCard() {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Upcoming Appointments",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // "See All" button in a separate row, aligned left
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('View all appointments - Coming soon!'),
                        ),
                      );
                    },
                    icon: const Text('See All', style: TextStyle(fontSize: 14)),
                    label: const Icon(Icons.chevron_right, size: 16),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(
                        left: 0,
                        top: 0,
                        bottom: 8,
                      ),
                      minimumSize: const Size(60, 24),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
                const Divider(),
              ],
            ),
            // Use Consumer with AppointmentProvider
            Consumer<AppointmentProvider>(
              builder: (context, appointmentProvider, child) {
                if (appointmentProvider.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final appointments = appointmentProvider.upcomingAppointments;

                if (appointments.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        "No upcoming appointments",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                  );
                }

                final nextAppointment = appointments.first;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            "Next Appointment",
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Cancel button moved to top row
                        TextButton.icon(
                          onPressed:
                              () => _showCancelConfirmation(nextAppointment),
                          icon: const Icon(Icons.cancel_outlined, size: 14),
                          label: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.error,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: const Size(30, 30),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${nextAppointment.category} (${nextAppointment.urgency})",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            nextAppointment.scheduledDateTime != null
                                ? "${dateFormat.format(nextAppointment.scheduledDateTime!)} at ${timeFormat.format(nextAppointment.scheduledDateTime!)}"
                                : "Date not specified",
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        // Use Consumer with ProviderDataProvider
                        Flexible(
                          child: Consumer<ProviderDataProvider>(
                            builder: (context, providerDataProvider, child) {
                              if (nextAppointment.providerId == null ||
                                  nextAppointment.providerId!.isEmpty) {
                                debugPrint(
                                  'Provider ID is null or empty for appointment: ${nextAppointment.id}',
                                );
                                return Text(
                                  "Provider: TBD",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                );
                              }

                              debugPrint(
                                'Found provider ID: ${nextAppointment.providerId}',
                              );
                              return FutureBuilder<String>(
                                future: providerDataProvider
                                    .getFormattedProviderName(
                                      nextAppointment.providerId!,
                                    ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Text(
                                      "Provider: Loading...",
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  }

                                  if (snapshot.hasData &&
                                      snapshot.data != "TBD") {
                                    return Text(
                                      "Provider: ${snapshot.data}",
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  }

                                  return Text(
                                    "Provider: TBD",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                () => _rescheduleAppointment(nextAppointment),
                            child: const Text('Reschedule'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                () => _checkInForAppointment(nextAppointment),
                            child: const Text('Start Now'),
                          ),
                        ),
                      ],
                    ),
                    if (appointments.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "You have ${appointments.length - 1} more upcoming appointment${appointments.length > 2 ? 's' : ''}",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Show confirmation dialog before cancelling an appointment
  void _showCancelConfirmation(PatientRequest appointment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Upcoming Appointment?'),
          content: const Text(
            'This will permanently cancel your appointment. This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No, Keep It'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _cancelAppointment(appointment);
              },
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Build the medical questions card
  Widget _buildMedicalQuestionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.healing,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Medical Questions",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // "See All" button in a separate row, aligned left
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('View all questions - Coming soon!'),
                        ),
                      );
                    },
                    icon: const Text('See All', style: TextStyle(fontSize: 14)),
                    label: const Icon(Icons.chevron_right, size: 16),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(
                        left: 0,
                        top: 0,
                        bottom: 8,
                      ),
                      minimumSize: const Size(60, 24),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
                const Divider(),
              ],
            ),
            // Use Consumer with MedicalQuestionsProvider
            Consumer<MedicalQuestionsProvider>(
              builder: (context, questionsProvider, child) {
                if (questionsProvider.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final pendingQuestions = questionsProvider.pendingQuestions;
                final answeredQuestions = questionsProvider.answeredQuestions;
                final allQuestions = [
                  ...pendingQuestions,
                  ...answeredQuestions,
                ];

                if (allQuestions.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        "No medical questions",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                  );
                }

                // Show up to 3 most recent questions
                final displayQuestions = allQuestions.take(3).toList();

                return Column(
                  children: [
                    ...displayQuestions.map(
                      (question) => _buildQuestionItem(question),
                    ),
                    if (allQuestions.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "You have ${allQuestions.length - 3} more question${allQuestions.length - 3 > 1 ? 's' : ''}",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
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

    return InkWell(
      onTap: () async {
        debugPrint('Navigating to question details for id: ${question.id}');
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => MedicalQuestionDetailsScreen(questionId: question.id),
          ),
        );

        debugPrint('Returned from question details with result: $result');

        // Always refresh when returning, regardless of result
        if (mounted) {
          debugPrint(
            'Refreshing questions after returning from details screen',
          );
          await Provider.of<MedicalQuestionsProvider>(
            context,
            listen: false,
          ).refreshQuestions();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                    question.status == 'pending' ? Colors.orange : Colors.green,
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
                  const SizedBox(height: 4),
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
                          question.status == 'pending' ? 'Pending' : 'Answered',
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
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
