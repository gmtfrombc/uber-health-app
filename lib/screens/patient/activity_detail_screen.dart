import 'package:flutter/material.dart';
import '../../widgets/consistent_app_bar.dart';

class ActivityDetailScreen extends StatefulWidget {
  final String activityType;

  const ActivityDetailScreen({super.key, required this.activityType});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _activityItems = [];

  @override
  void initState() {
    super.initState();

    // Load data when screen first loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActivityData();
    });
  }

  // This method would fetch actual data from a data source
  Future<void> _loadActivityData() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Create placeholder data based on activity type
    final List<Map<String, dynamic>> items = [];

    switch (widget.activityType) {
      case 'Visits':
        items.addAll([
          {
            'title': 'Knee Pain Visit',
            'date': '05/15/2024',
            'status': 'Completed',
          },
          {
            'title': 'Cough and Cold Visit',
            'date': '03/22/2023',
            'status': 'Completed',
          },
          {
            'title': 'Ankle Pain Visit',
            'date': '01/10/2023',
            'status': 'Completed',
          },
        ]);
        break;
      case 'Tests':
        items.addAll([
          {
            'title': 'Complete Blood Count',
            'date': '04/12/2023',
            'status': 'Completed',
          },
          {'title': 'Lipid Panel', 'date': '04/12/2023', 'status': 'Completed'},
          {'title': 'X-Ray Ankle', 'date': '03/05/2023', 'status': 'Completed'},
          {'title': 'MRI Knee', 'date': '01/10/2023', 'status': 'Completed'},
        ]);
        break;
      case 'Questions':
        items.addAll([
          {
            'title': 'When can I resume sports activity?',
            'date': '05/15/2023',
            'status': 'Answered',
          },
          {
            'title': 'How long should I ice my knee?',
            'date': '03/22/2023',
            'status': 'Answered',
          },
          {
            'title': 'Do I need to use crutches?',
            'date': '02/18/2023',
            'status': 'Answered',
          },
        ]);
        break;
      case 'Prescriptions':
        items.addAll([
          {
            'title': 'Lisinopril 10mg',
            'date': '05/15/2023',
            'status': 'Active',
          },
          {
            'title': 'Atorvastatin 20mg',
            'date': '05/15/2023',
            'status': 'Active',
          },
          {
            'title': 'Naproxen 500mg',
            'date': '01/10/2023',
            'status': 'Expired',
          },
        ]);
        break;
      case 'Therapies':
        items.addAll([
          {
            'title': 'Knee Rehabilitation',
            'date': '05/15/2023',
            'status': 'Active',
          },
          {
            'title': 'Lower Back Strengthening',
            'date': '03/22/2023',
            'status': 'Completed',
          },
          {
            'title': 'Shoulder Mobility Exercises',
            'date': '01/10/2023',
            'status': 'Completed',
          },
        ]);
        break;
      default:
        items.addAll([
          {'title': 'No data available', 'date': '-', 'status': '-'},
        ]);
    }

    if (mounted) {
      setState(() {
        _activityItems = items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: ConsistentAppBar(title: widget.activityType),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
              : _activityItems.isEmpty
              ? Center(
                child: Text(
                  'No ${widget.activityType} data available',
                  style: theme.textTheme.bodyLarge,
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                itemCount: _activityItems.length,
                separatorBuilder:
                    (context, index) =>
                        Divider(color: theme.dividerTheme.color),
                itemBuilder: (context, index) {
                  final item = _activityItems[index];
                  return ListTile(
                    title: Text(
                      item['title'],
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: Text('Date: ${item['date']}'),
                    trailing: Chip(
                      label: Text(
                        item['status'],
                        style: TextStyle(
                          color: _getStatusColor(item['status']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: _getStatusColor(
                        item['status'],
                      ).withAlpha(30),
                    ),
                    onTap: () {
                      // Would navigate to specific detail screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Viewing details for ${item['title']}'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }

  Color _getStatusColor(String status) {
    final theme = Theme.of(context);

    switch (status.toLowerCase()) {
      case 'completed':
      case 'available':
      case 'answered':
      case 'resolved':
        return Colors.green;
      case 'active':
        return theme.colorScheme.primary;
      case 'pending':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
