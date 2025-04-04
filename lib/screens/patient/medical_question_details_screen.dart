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
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuestionDetails();
  }

  Future<void> _loadQuestionDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final questionsProvider = Provider.of<MedicalQuestionsProvider>(
        context,
        listen: false,
      );

      final question = await questionsProvider.getQuestionDetails(
        widget.questionId,
      );

      if (question != null) {
        setState(() {
          _question = question;
          _isLoading = false;
        });

        // If the question is answered but not read, mark it as read automatically
        if (question.status == 'answered' && !question.isRead) {
          await questionsProvider.markQuestionAsRead(widget.questionId);
        }
      } else {
        setState(() {
          _error = 'Question not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading question: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy - h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Medical Question'), elevation: 0),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_error!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadQuestionDetails,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : _question == null
              ? const Center(child: Text('Question not found'))
              : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Question Card
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Your Question',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'MMM d, yyyy',
                                ).format(_question!.timestamp),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
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
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      _formatDate(_question!.timestamp),
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
                                      _question!.status == 'pending'
                                          ? Colors.orange.shade100
                                          : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _question!.status == 'pending'
                                      ? 'Pending'
                                      : 'Answered',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        _question!.status == 'pending'
                                            ? Colors.orange.shade800
                                            : Colors.green.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _question!.question,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Status Bar
                  const SizedBox(height: 8),
                  _buildStatusBar(),

                  // Provider Response Card (if answered)
                  if (_question!.status == 'answered' &&
                      _question!.providerResponse != null) ...[
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Provider Response',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      if (_question!.providerId != null)
                                        Text(
                                          _question!.providerName ??
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
                              _question!.providerResponse!,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Action buttons
                  const SizedBox(height: 24),
                  _buildActions(),
                ],
              ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder:
                      (dialogContext) => AlertDialog(
                        title: const Text('Mark as Done'),
                        content: const Text(
                          'Are you sure you want to mark this question as done? '
                          'It will no longer appear in your active questions list.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('CANCEL'),
                          ),
                          TextButton(
                            onPressed: () {
                              // Close the dialog first
                              Navigator.of(dialogContext).pop();

                              // Then handle the async operation separately
                              _handleMarkAsDone();
                            },
                            child: const Text('MARK AS DONE'),
                          ),
                        ],
                      ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).primaryColor,
                side: BorderSide(color: Theme.of(context).primaryColor),
              ),
              child: const Text('Done with Question'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMarkAsDone() async {
    final questionsProvider = Provider.of<MedicalQuestionsProvider>(
      context,
      listen: false,
    );

    setState(() {
      _isLoading = true;
    });

    bool success = false;
    String? errorMessage;

    try {
      // Mark as done (uses markQuestionAsDone for answered questions)
      if (_question!.status == 'answered') {
        await questionsProvider.markQuestionAsDone(widget.questionId);
        success = true;
      } else {
        // For pending questions, mark as resolved
        success = await questionsProvider.markQuestionAsResolved(
          widget.questionId,
        );
      }
    } catch (e) {
      errorMessage = 'Error: $e';
      success = false;
    }

    // We use a closure to handle UI updates instead of using BuildContext directly
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (!success && errorMessage != null) {
        _error = errorMessage;
      }
    });

    // Manually trigger a refresh of the questions list to update badges
    if (success) {
      questionsProvider.refreshQuestions();

      // Use a callback to post the navigation action to the event queue
      // This ensures we're not using context during the build phase
      Future.microtask(() {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      });
    }
  }

  Widget _buildStatusBar() {
    final String statusText =
        _question!.status == 'pending'
            ? 'Question Status: Pending'
            : _question!.status == 'answered'
            ? 'Question Status: Answered'
            : 'Question Status: ${_question!.status}';

    final Color statusColor =
        _question!.status == 'pending'
            ? Colors
                .orange
                .shade800 // Orange
            : _question!.status == 'answered'
            ? Colors
                .green
                .shade800 // Green
            : Theme.of(context).primaryColor; // Default

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: statusColor.withAlpha(40),
      child: Row(
        children: [
          Icon(
            _question!.status == 'pending'
                ? Icons.access_time
                : _question!.status == 'answered'
                ? Icons.check_circle
                : Icons.info,
            color: statusColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
