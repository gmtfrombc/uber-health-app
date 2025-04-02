import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/medical_questions_provider.dart';

class MedicalQuestionDetailsScreen extends StatefulWidget {
  final String questionId;

  const MedicalQuestionDetailsScreen({super.key, required this.questionId});

  @override
  State<MedicalQuestionDetailsScreen> createState() =>
      _MedicalQuestionDetailsScreenState();
}

class _MedicalQuestionDetailsScreenState
    extends State<MedicalQuestionDetailsScreen> {
  bool _isLoading = false;
  MedicalQuestion? _question;

  @override
  void initState() {
    super.initState();
    _loadQuestionDetails();
  }

  Future<void> _loadQuestionDetails() async {
    setState(() {
      _isLoading = true;
    });

    final questionsProvider = Provider.of<MedicalQuestionsProvider>(
      context,
      listen: false,
    );

    final question = await questionsProvider.getQuestionDetails(
      widget.questionId,
    );

    if (mounted) {
      setState(() {
        _question = question;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsResolved() async {
    if (_question == null) return;

    // Show confirmation dialog
    final bool confirmResolve =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Mark Question as Resolved'),
                content: const Text(
                  'This will remove the question from your home screen. Are you sure you want to proceed?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Yes, I\'m Done'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirmResolve) return;

    final questionsProvider = Provider.of<MedicalQuestionsProvider>(
      context,
      listen: false,
    );

    setState(() {
      _isLoading = true;
    });

    final success = await questionsProvider.markQuestionAsResolved(
      _question!.id,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        // Show confirmation to the user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question marked as resolved')),
        );

        // Force refresh to ensure the UI is updated
        await questionsProvider.refreshQuestions();

        // Navigate back to home screen with result
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark question as resolved')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy - h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medical Question')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _question == null
              ? const Center(child: Text('Question not found'))
              : _buildQuestionDetails(),
    );
  }

  Widget _buildQuestionDetails() {
    final question = _question!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Card
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.question_answer,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Question',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatDate(question.timestamp),
                              style: theme.textTheme.bodySmall,
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
                              question.status == 'pending'
                                  ? Colors.orange.shade100
                                  : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          question.status == 'pending' ? 'Pending' : 'Answered',
                          style: TextStyle(
                            fontSize: 12,
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
                  const SizedBox(height: 16),
                  Text(question.question, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ),

          // Provider Response Card (only if answered)
          if (question.status == 'answered' &&
              question.providerResponse != null) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.medical_services,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Provider Response',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (question.providerId != null)
                                Text(
                                  question.providerName ??
                                      'Healthcare Provider',
                                  style: theme.textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      question.providerResponse!,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Action buttons
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: _markAsResolved,
              icon: const Icon(Icons.check_circle),
              label: const Text('Done with Question'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
