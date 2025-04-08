import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/patient_request.dart';
import '../providers/provider_data_provider.dart';

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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: theme.dividerColor, width: 1),
      ),
      elevation: 1,
      color: isDarkMode ? theme.cardColor : Colors.white,
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
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
                    style: ButtonStyle(
                      foregroundColor: WidgetStateProperty.all(
                        theme.colorScheme.error,
                      ),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      minimumSize: WidgetStateProperty.all(const Size(30, 30)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "${appointment.category} (${appointment.urgency})",
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    appointment.scheduledDateTime != null
                        ? "${dateFormat.format(appointment.scheduledDateTime!)} at ${timeFormat.format(appointment.scheduledDateTime!)}"
                        : "Date not specified",
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                // Provider name
                Flexible(
                  child: Consumer<ProviderDataProvider>(
                    builder: (context, providerDataProvider, child) {
                      if (appointment.providerId == null ||
                          appointment.providerId!.isEmpty) {
                        return Text(
                          "Provider: TBD",
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        );
                      }

                      return FutureBuilder<String>(
                        future: providerDataProvider.getFormattedProviderName(
                          appointment.providerId!,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Text(
                              "Provider: Loading...",
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            );
                          }

                          final providerName = snapshot.data ?? "TBD";
                          return Text(
                            "Provider: $providerName",
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
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
                        style: ButtonStyle(
                          foregroundColor: WidgetStateProperty.all(
                            theme.colorScheme.primary,
                          ),
                          side: WidgetStateProperty.all(
                            BorderSide(color: theme.colorScheme.primary),
                          ),
                        ),
                        child: const Text('Reschedule'),
                      ),
                    ),
                  if (onReschedule != null && onCheckIn != null)
                    const SizedBox(width: 8),
                  if (onCheckIn != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => onCheckIn!(appointment),
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                            theme.colorScheme.primary,
                          ),
                          foregroundColor: WidgetStateProperty.all(
                            Colors.white,
                          ),
                        ),
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Upcoming Appointment?'),
          content: const Text(
            'This will permanently cancel your appointment. This action cannot be undone.',
          ),
          backgroundColor:
              isDarkMode ? theme.dialogBackgroundColor : Colors.white,
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.all(
                  theme.textTheme.bodyLarge?.color,
                ),
              ),
              child: const Text('No, Keep It'),
            ),
            TextButton(
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.all(
                  theme.colorScheme.error,
                ),
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
