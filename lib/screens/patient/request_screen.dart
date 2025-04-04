// lib/screens/patient/request_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/request_provider.dart';
import '../../models/patient_request.dart';
import '../../theme.dart';
import 'category_selection_screen.dart';
import '../consultation/chat_interface.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.softShadow,
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
                      color: AppTheme.primaryColor,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Choose Provider Type',
                      style: Theme.of(context).textTheme.titleLarge,
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
                                  ? AppTheme.primaryColor.withAlpha(20)
                                  : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                requestProvider.providerType ==
                                        ProviderType.medicalProvider
                                    ? AppTheme.primaryColor
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
                                        ? AppTheme.primaryColor
                                        : Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                FontAwesomeIcons.userDoctor,
                                color:
                                    requestProvider.providerType ==
                                            ProviderType.medicalProvider
                                        ? Colors.white
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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          requestProvider.providerType ==
                                                  ProviderType.medicalProvider
                                              ? AppTheme.primaryDarkColor
                                              : AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'General health, medication, diagnoses',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                    ),
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
                                      ? AppTheme.primaryColor
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
                                  ? AppTheme.primaryColor.withAlpha(20)
                                  : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                requestProvider.providerType ==
                                        ProviderType.physicalTherapist
                                    ? AppTheme.primaryColor
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
                                        ? AppTheme.primaryColor
                                        : Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                FontAwesomeIcons.dumbbell,
                                color:
                                    requestProvider.providerType ==
                                            ProviderType.physicalTherapist
                                        ? Colors.white
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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          requestProvider.providerType ==
                                                  ProviderType.physicalTherapist
                                              ? AppTheme.primaryDarkColor
                                              : AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Injuries, rehabilitation, exercises',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                    ),
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
                                      ? AppTheme.primaryColor
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(timing, style: Theme.of(context).textTheme.bodySmall),
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
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Request Care'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient header section with descriptive text
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How can we help you today?',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a provider type and consultation option below',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withAlpha(230),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Provider toggle section
            providerToggle(),

            const SizedBox(height: 24),

            // Consultation section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    FontAwesomeIcons.calendarCheck,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Consultation Options',
                    style: Theme.of(context).textTheme.titleLarge,
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
              accentColor: AppTheme.highUrgencyColor,
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
              accentColor: AppTheme.primaryColor,
            ),

            // Divider with padding
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Divider(thickness: 1, color: Colors.grey.shade300),
            ),

            // Medical Questions section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    FontAwesomeIcons.circleQuestion,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Medical Questions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
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
              accentColor: AppTheme.infoColor,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
