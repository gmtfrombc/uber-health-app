// lib/screens/scheduling_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/request_provider.dart';
import 'chat_interface.dart';

class SchedulingScreen extends StatefulWidget {
  final String urgency; // Should be "Routine"
  const SchedulingScreen({super.key, required this.urgency});

  @override
  State<SchedulingScreen> createState() => _SchedulingScreenState();
}

class _SchedulingScreenState extends State<SchedulingScreen> {
  late DateTime scheduledDateTime;

  @override
  void initState() {
    super.initState();
    // Set the default scheduled time to one hour later, rounded to the next 15-minute interval.
    scheduledDateTime = _getRoundedTime(
      DateTime.now().add(const Duration(hours: 1)),
    );
  }

  // Helper function to round a DateTime to the next 15-minute interval.
  DateTime _getRoundedTime(DateTime dt) {
    int minute = dt.minute;
    int mod = minute % 15;
    if (mod != 0) {
      // Subtract the remainder and add 15 minutes to get to the next interval.
      dt = dt.subtract(Duration(minutes: mod)).add(const Duration(minutes: 15));
    }
    return dt;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Your Consult')),
      body: Column(
        children: [
          Expanded(
            child: CupertinoDatePicker(
              initialDateTime: scheduledDateTime,
              mode: CupertinoDatePickerMode.dateAndTime,
              minuteInterval: 15,
              onDateTimeChanged: (newDateTime) {
                setState(() {
                  scheduledDateTime = newDateTime;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // Save the selected date/time in RequestProvider.
                Provider.of<RequestProvider>(
                  context,
                  listen: false,
                ).setScheduledDateTime(scheduledDateTime);
                // Navigate to ChatInterface so the AI triage assistant can take the patient's history.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ChatInterface(
                          isSynchronous: true,
                          isImmediate: false,
                          urgency: widget.urgency,
                        ),
                  ),
                );
              },
              child: const Text('Confirm Appointment'),
            ),
          ),
        ],
      ),
    );
  }
}
