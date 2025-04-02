// lib/screens/patient/home_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _checkedAppointments = false;

  Future<UserModel?> _fetchUser() async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (uid.isEmpty) return null;
    final user = await _firebaseService.getUserMedicalInfo(uid);

    // Check for upcoming appointments
    if (!_checkedAppointments) {
      _checkUpcomingAppointments();
      _checkedAppointments = true;
    }

    return user;
  }

  // Helper method to format a list of items with bullets.
  String _formatListWithBullets(List<String>? items) {
    if (items == null || items.isEmpty) return "None";
    return items.map((item) => "• $item").join("\n");
  }

  // Check for upcoming appointments
  Future<void> _checkUpcomingAppointments() async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (uid.isEmpty) return;

    try {
      // Get appointments within the next 15 minutes
      final appointments = await _firebaseService.getImmediateAppointments(uid);

      if (appointments.isNotEmpty && mounted) {
        // We have an upcoming appointment, show check-in dialog
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showAppointmentCheckInDialog(appointments.first);
        });
      }
    } catch (e) {
      debugPrint('Error checking appointments: $e');
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
      await _firebaseService.updateAppointmentStatus(
        appointment.id,
        RequestStatus.cancelled,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment cancelled successfully')),
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
      appBar: AppBar(title: const Text('Uber Health')),
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
                              Text(
                                "Your Health Information",
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
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
                          child: const Text('Request a Consult'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          _formatListWithBullets(items),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    "Upcoming Appointments",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to all appointments screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('View all appointments - Coming soon!'),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    minimumSize: Size(60, 36),
                  ),
                  child: const Text('See All', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
            const Divider(),
            FutureBuilder<List<PatientRequest>>(
              future: _firebaseService.getUpcomingAppointments(
                FirebaseAuth.instance.currentUser?.uid ?? "",
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
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

                // Display the next appointment
                final appointments = snapshot.data!;
                final nextAppointment = appointments.first;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Next Appointment",
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Flexible(
                            child: Text(
                              "${nextAppointment.category} (${nextAppointment.urgency})",
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
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
                              Flexible(
                                child: Text(
                                  "Provider: ${nextAppointment.providerType.name}",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
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
                                      () => _rescheduleAppointment(
                                        nextAppointment,
                                      ),
                                  child: const Text('Reschedule'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      () => _checkInForAppointment(
                                        nextAppointment,
                                      ),
                                  child: const Text('Start Now'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
}
