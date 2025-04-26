// lib/screens/patient/request_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/request_provider.dart';
import '../../models/patient_request.dart';
import '../../widgets/consistent_app_bar.dart';
import 'category_selection_screen.dart';
import '../consultation/chat_interface.dart';

class RequestScreen extends StatefulWidget {
  final ProviderType? forcedProviderType;

  const RequestScreen({this.forcedProviderType, super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  int selectedProviderToggleIndex = 0; // 0: Medical, 1: Physical Therapist

  @override
  void initState() {
    super.initState();
    // Initialize UI state without modifying the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final requestProvider = Provider.of<RequestProvider>(
        context,
        listen: false,
      );

      // Clear request data while preserving provider type
      requestProvider.clearRequest();

      // If a provider type was forced, apply it
      if (widget.forcedProviderType != null) {
        requestProvider.setProviderType(widget.forcedProviderType!);
      }

      // Set UI state based on provider state
      setState(() {
        selectedProviderToggleIndex =
            requestProvider.providerType == ProviderType.medicalProvider
                ? 0
                : 1;
      });

      debugPrint(
        'DEBUG: Request screen initialized with provider type: ${requestProvider.providerType.name}',
      );
    });
  }

  // Provider type toggle widget with enhanced design
  Widget providerToggle() {
    // Use Consumer to rebuild when provider type changes
    return Consumer<RequestProvider>(
      builder: (context, requestProvider, _) {
        final theme = Theme.of(context);
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        // Update UI toggle if it doesn't match provider state
        if ((requestProvider.providerType == ProviderType.medicalProvider &&
                selectedProviderToggleIndex != 0) ||
            (requestProvider.providerType == ProviderType.physicalTherapist &&
                selectedProviderToggleIndex != 1)) {
          // This is a defensive measure that should rarely be needed
          debugPrint(
            'Syncing UI toggle with provider state: ${requestProvider.providerType.name}',
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              selectedProviderToggleIndex =
                  requestProvider.providerType == ProviderType.medicalProvider
                      ? 0
                      : 1;
            });
          });
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? theme.colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    isDarkMode
                        ? Colors.black.withAlpha(77)
                        : Colors.black.withAlpha(26),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_hospital_rounded,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Choose Provider Type',
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    // Medical Provider Option with enhanced UI
                    InkWell(
                      onTap: () {
                        setState(() {
                          selectedProviderToggleIndex = 0;
                          requestProvider.setProviderType(
                            ProviderType.medicalProvider,
                          );
                          debugPrint(
                            'Provider type changed to: ${ProviderType.medicalProvider.name}',
                          );
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color:
                              requestProvider.providerType ==
                                      ProviderType.medicalProvider
                                  ? theme.colorScheme.primary.withAlpha(20)
                                  : isDarkMode
                                  ? theme.colorScheme.surface.withAlpha(150)
                                  : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                requestProvider.providerType ==
                                        ProviderType.medicalProvider
                                    ? theme.colorScheme.primary
                                    : isDarkMode
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color:
                                    requestProvider.providerType ==
                                            ProviderType.medicalProvider
                                        ? theme.colorScheme.primary
                                        : isDarkMode
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                FontAwesomeIcons.userDoctor,
                                color:
                                    requestProvider.providerType ==
                                            ProviderType.medicalProvider
                                        ? Colors.white
                                        : isDarkMode
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade600,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Medical Provider',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              requestProvider.providerType ==
                                                      ProviderType
                                                          .medicalProvider
                                                  ? theme.colorScheme.primary
                                                  : theme
                                                      .textTheme
                                                      .titleMedium
                                                      ?.color,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'General health, medication, diagnoses',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              requestProvider.providerType ==
                                      ProviderType.medicalProvider
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color:
                                  requestProvider.providerType ==
                                          ProviderType.medicalProvider
                                      ? theme.colorScheme.primary
                                      : isDarkMode
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade400,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Physical Therapist Option with enhanced UI
                    InkWell(
                      onTap: () {
                        setState(() {
                          selectedProviderToggleIndex = 1;
                          requestProvider.setProviderType(
                            ProviderType.physicalTherapist,
                          );
                          debugPrint(
                            'Provider type changed to: ${ProviderType.physicalTherapist.name}',
                          );
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color:
                              requestProvider.providerType ==
                                      ProviderType.physicalTherapist
                                  ? theme.colorScheme.primary.withAlpha(20)
                                  : isDarkMode
                                  ? theme.colorScheme.surface.withAlpha(150)
                                  : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                requestProvider.providerType ==
                                        ProviderType.physicalTherapist
                                    ? theme.colorScheme.primary
                                    : isDarkMode
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color:
                                    requestProvider.providerType ==
                                            ProviderType.physicalTherapist
                                        ? theme.colorScheme.primary
                                        : isDarkMode
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                FontAwesomeIcons.dumbbell,
                                color:
                                    requestProvider.providerType ==
                                            ProviderType.physicalTherapist
                                        ? Colors.white
                                        : isDarkMode
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade600,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Physical Therapist',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              requestProvider.providerType ==
                                                      ProviderType
                                                          .physicalTherapist
                                                  ? theme.colorScheme.primary
                                                  : theme
                                                      .textTheme
                                                      .titleMedium
                                                      ?.color,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Injuries, rehabilitation, exercises',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              requestProvider.providerType ==
                                      ProviderType.physicalTherapist
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color:
                                  requestProvider.providerType ==
                                          ProviderType.physicalTherapist
                                      ? theme.colorScheme.primary
                                      : isDarkMode
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade400,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build a tile for each consultation option with enhanced design
  Widget buildTile({
    required BuildContext context,
    required RequestType type,
    required String urgency,
    required String title,
    required String timing,
    required String price,
    required IconData icon,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? Colors.black.withAlpha(77)
                    : Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
            final requestProvider = Provider.of<RequestProvider>(
              context,
              listen: false,
            );
            // For consults, default category is "Other"; for questions, default to "Medical Question".
            String category =
                type == RequestType.consult ? "Other" : "Medical Question";
            requestProvider.createRequest(
              PatientRequest(
                patientId: uid,
                requestType: type,
                urgency: urgency,
                category: category,
                providerType: requestProvider.providerType,
              ),
            );
            if (type == RequestType.consult) {
              // Add debug print to check provider type before navigation
              debugPrint(
                'DEBUG: Provider type before navigation: ${requestProvider.providerType.name}',
              );

              // Navigate to CategorySelectionScreen - no need to pass provider type
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategorySelectionScreen(urgency: urgency),
                ),
              );
            } else {
              // For questions, navigate directly to ChatInterface
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => ChatInterface(
                        isSynchronous: false,
                        isImmediate: true,
                        urgency: "Routine",
                      ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Left icon section
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 28),
                ),
                const SizedBox(width: 16),
                // Center text section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(timing, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                // Right price section
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    price,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const ConsistentAppBar(title: 'Request Care'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.forcedProviderType == null) ...[
              // Header section with descriptive text
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Consult or Ask Question',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Provider toggle section
              providerToggle(),

              const SizedBox(height: 24),
            ],

            // Consultation section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    FontAwesomeIcons.calendarCheck,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Consultation Options',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Quick Consult Option
            buildTile(
              context: context,
              type: RequestType.consult,
              urgency: 'Quick',
              title: 'Quick Consult',
              timing: 'Available now',
              price: '\$70',
              icon: FontAwesomeIcons.bolt,
              accentColor: theme.colorScheme.secondary,
            ),

            // Routine Consult Option
            buildTile(
              context: context,
              type: RequestType.consult,
              urgency: 'Routine',
              title: 'Routine Consult',
              timing: 'Schedule an appointment',
              price: '\$50',
              icon: FontAwesomeIcons.calendar,
              accentColor: theme.colorScheme.primary,
            ),

            // Divider with padding
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Divider(
                thickness: 1,
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),

            // Medical Questions section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    FontAwesomeIcons.circleQuestion,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text('Medical Questions', style: theme.textTheme.titleLarge),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Medical Question Option
            buildTile(
              context: context,
              type: RequestType.medicalQuestion,
              urgency: 'Routine',
              title: 'Routine Medical Question',
              timing: 'Response time: less than 1 hour',
              price: '\$30',
              icon: FontAwesomeIcons.comment,
              accentColor: Colors.blue,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
