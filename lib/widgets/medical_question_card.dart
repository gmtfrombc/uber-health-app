import 'package:flutter/material.dart';
import '../providers/medical_questions_provider.dart'; // Use MedicalQuestion
import 'package:intl/intl.dart';
import '../screens/patient/medical_question_details_screen.dart';

class MedicalQuestionCard extends StatelessWidget {
  final MedicalQuestion question;

  const MedicalQuestionCard({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final String formattedDate = dateFormat.format(question.timestamp);
    final bool isAnswered = question.status.toLowerCase() == 'answered';

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: theme.dividerColor, width: 1),
      ),
      elevation: 1,
      child: ListTile(
        leading: Icon(
          isAnswered ? Icons.mark_chat_read_outlined : Icons.help_outline,
          color: isAnswered ? Colors.green : theme.colorScheme.primary,
        ),
        title: Text(
          question.question,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('Asked on $formattedDate - Status: ${question.status}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => MedicalQuestionDetailsScreen(questionId: question.id),
            ),
          );
          debugPrint('Tapped question: ${question.id}');
        },
      ),
    );
  }
}
