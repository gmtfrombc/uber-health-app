// lib/screens/patient/request_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/request_provider.dart';
import '../../models/patient_request.dart';
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

  // Provider type toggle widget.
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
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Provider Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  // Medical Provider Option
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
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            requestProvider.providerType ==
                                    ProviderType.medicalProvider
                                ? Theme.of(
                                  context,
                                ).colorScheme.primary.withAlpha(38)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              requestProvider.providerType ==
                                      ProviderType.medicalProvider
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            requestProvider.providerType ==
                                    ProviderType.medicalProvider
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color:
                                requestProvider.providerType ==
                                        ProviderType.medicalProvider
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.medical_services),
                          const SizedBox(width: 12),
                          const Text(
                            'Medical Provider',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Physical Therapist Option
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
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            requestProvider.providerType ==
                                    ProviderType.physicalTherapist
                                ? Theme.of(
                                  context,
                                ).colorScheme.primary.withAlpha(38)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              requestProvider.providerType ==
                                      ProviderType.physicalTherapist
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            requestProvider.providerType ==
                                    ProviderType.physicalTherapist
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color:
                                requestProvider.providerType ==
                                        ProviderType.physicalTherapist
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.fitness_center),
                          const SizedBox(width: 12),
                          const Text(
                            'Physical Therapist',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                requestProvider.providerType == ProviderType.medicalProvider
                    ? 'Consult with a medical providers who can treat general health conditions'
                    : 'Consult with a physical therapists who specialize in acute injuries',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build a tile for each consultation option.
  Widget buildTile({
    required BuildContext context,
    required RequestType type,
    required String urgency,
    required String title,
    required String timing,
    required String price,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(timing),
        trailing: Text(price, style: const TextStyle(fontSize: 16)),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consult/Question')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            providerToggle(),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Consultation Options',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            // Quick Consult Option
            buildTile(
              context: context,
              type: RequestType.consult,
              urgency: 'Quick',
              title: 'Quick Consult',
              timing: 'Available now',
              price: '\$70',
            ),
            // Routine Consult Option
            buildTile(
              context: context,
              type: RequestType.consult,
              urgency: 'Routine',
              title: 'Routine Consult',
              timing: 'Schedule an appointment',
              price: '\$50',
            ),
            const Divider(height: 40, thickness: 2),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Medical Questions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            // Medical Question Option
            buildTile(
              context: context,
              type: RequestType.medicalQuestion,
              urgency: 'Routine',
              title: 'Routine Medical Question',
              timing: 'Response time: less than 1 hour',
              price: '\$30',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
