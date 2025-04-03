import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/patient_request.dart';
import '../providers/provider_data_provider.dart';
import '../theme.dart';

class AppointmentCard extends StatelessWidget {
  final PatientRequest appointment;
  final Function(PatientRequest)? onCancel;
  final Function(PatientRequest)? onReschedule;
  final Function(PatientRequest)? onCheckIn;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onCancel,
    this.onReschedule,
    this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: AppTheme.textTertiaryColor.withAlpha(51),
          width: 1,
        ),
      ),
      elevation: 1,
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
                    "Appointment Details",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Cancel button
                if (onCancel != null)
                  TextButton.icon(
                    onPressed: () => _showCancelConfirmation(context),
                    icon: const Icon(Icons.cancel_outlined, size: 14),
                    label: const Text('Cancel', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(30, 30),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "${appointment.category} (${appointment.urgency})",
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    appointment.scheduledDateTime != null
                        ? "${dateFormat.format(appointment.scheduledDateTime!)} at ${timeFormat.format(appointment.scheduledDateTime!)}"
                        : "Date not specified",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                // Provider name
                Flexible(
                  child: Consumer<ProviderDataProvider>(
                    builder: (context, providerDataProvider, child) {
                      if (appointment.providerId == null ||
                          appointment.providerId!.isEmpty) {
                        return const Text(
                          "Provider: TBD",
                          style: TextStyle(fontSize: 14),
                        );
                      }

                      return FutureBuilder<String>(
                        future: providerDataProvider.getFormattedProviderName(
                          appointment.providerId!,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text("Provider: Loading...");
                          }

                          final providerName = snapshot.data ?? "TBD";
                          return Text(
                            "Provider: $providerName",
                            style: const TextStyle(fontSize: 14),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            if (onReschedule != null || onCheckIn != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (onReschedule != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onReschedule!(appointment),
                        child: const Text('Reschedule'),
                      ),
                    ),
                  if (onReschedule != null && onCheckIn != null)
                    const SizedBox(width: 8),
                  if (onCheckIn != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => onCheckIn!(appointment),
                        child: const Text('Start Now'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context) {
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
                if (onCancel != null) {
                  onCancel!(appointment);
                }
              },
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }
}
