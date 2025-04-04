import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

/// A screen to display detailed error information when the app encounters
/// an unexpected exception. This provides users with information they can
/// share with support.
class ErrorDetailsScreen extends StatelessWidget {
  final String errorMessage;
  final String? stackTrace;
  final DateTime timestamp;
  final VoidCallback? onRetry;

  const ErrorDetailsScreen({
    super.key,
    required this.errorMessage,
    this.stackTrace,
    required this.timestamp,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Details'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'We apologize for the inconvenience. The error has been logged and will be addressed.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _buildInfoCard(
              context,
              title: 'Error Information',
              content: errorMessage,
            ),
            if (stackTrace != null) ...[
              const SizedBox(height: 16),
              _buildInfoCard(
                context,
                title: 'Technical Details',
                content: stackTrace!,
                maxLines: 10,
                monospace: true,
              ),
            ],
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              title: 'Timestamp',
              content: _formatTimestamp(timestamp),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    final errorInfo = '''
Error: $errorMessage
Time: ${_formatTimestamp(timestamp)}
${stackTrace != null ? '\nStack Trace: $stackTrace' : ''}
''';
                    Clipboard.setData(ClipboardData(text: errorInfo));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error details copied to clipboard'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Return to App'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String content,
    int? maxLines,
    bool monospace = false,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                content,
                style:
                    monospace
                        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        )
                        : Theme.of(context).textTheme.bodyMedium,
                maxLines: maxLines,
                overflow: maxLines != null ? TextOverflow.ellipsis : null,
              ),
            ),
            if (maxLines != null && content.split('\n').length > maxLines)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text(title),
                            content: SingleChildScrollView(
                              child: Text(
                                content,
                                style:
                                    monospace
                                        ? const TextStyle(
                                          fontFamily: 'monospace',
                                        )
                                        : null,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                    );
                  },
                  child: const Text('Show More'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }
}
