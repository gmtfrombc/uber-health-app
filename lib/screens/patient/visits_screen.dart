import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/medical_questions_provider.dart';
import '../../widgets/appointment_card.dart'; // Will create this
import '../../widgets/medical_question_card.dart'; // Will create this

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppointmentProvider>(
        context,
        listen: false,
      ).refreshAppointments();
      Provider.of<MedicalQuestionsProvider>(
        context,
        listen: false,
      ).refreshQuestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visits & Questions'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<AppointmentProvider>(
            context,
            listen: false,
          ).refreshAppointments();
          await Provider.of<MedicalQuestionsProvider>(
            context,
            listen: false,
          ).refreshQuestions();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionTitle(context, 'Upcoming Appointments'),
            _buildAppointmentList(context),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Medical Questions'),
            _buildMedicalQuestionList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: theme.textTheme.headlineSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAppointmentList(BuildContext context) {
    return Consumer<AppointmentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error.isNotEmpty) {
          return Center(child: Text('Error: ${provider.error}'));
        }
        if (provider.upcomingAppointments.isEmpty) {
          return const Center(child: Text('No upcoming appointments.'));
        }
        return ListView.builder(
          shrinkWrap: true, // Important for ListView inside ListView
          physics:
              const NeverScrollableScrollPhysics(), // Disable nested scrolling
          itemCount: provider.upcomingAppointments.length,
          itemBuilder: (context, index) {
            final appointment = provider.upcomingAppointments[index];
            return AppointmentCard(appointment: appointment);
          },
        );
      },
    );
  }

  Widget _buildMedicalQuestionList(BuildContext context) {
    return Consumer<MedicalQuestionsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.questions.isEmpty) {
          return const Center(child: Text('No medical questions found.'));
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.questions.length,
          itemBuilder: (context, index) {
            final question = provider.questions[index];
            return MedicalQuestionCard(question: question);
          },
        );
      },
    );
  }
}
