// lib/screens/patient/category_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/patient_request.dart';
import '../../models/chat_mode.dart';
import '../../providers/request_provider.dart';
import '../../providers/provider_provider.dart';
import '../../utils/categories.dart';
import './provider_list_screen.dart';
import './scheduling_screen.dart';
import '../consultation/chat_interface.dart';

class CategorySelectionScreen extends StatelessWidget {
  final String urgency;
  final ChatMode chatMode;
  final String? appointmentId;

  const CategorySelectionScreen({
    super.key,
    required this.urgency,
    this.chatMode = ChatMode.regular,
    this.appointmentId,
  });

  @override
  Widget build(BuildContext context) {
    final providerType =
        Provider.of<RequestProvider>(context, listen: false).providerType;
    final List<Map<String, String>> categories =
        providerType == ProviderType.medicalProvider
            ? medicalProviderCategories
            : physicalTherapistCategories;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text("Choose a Category")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What brings you in today?",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              "Select the category that best describes your symptoms",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio:
                    0.9, // Adjust aspect ratio to make cards taller
                children: List.generate(categories.length, (index) {
                  final category = categories[index];
                  return GestureDetector(
                    onTap: () {
                      final String uid =
                          FirebaseAuth.instance.currentUser?.uid ?? '';
                      final requestProvider = Provider.of<RequestProvider>(
                        context,
                        listen: false,
                      );
                      // Set the selected category.
                      requestProvider.setCategory(category['title']!);

                      // Create a new PatientRequest with the required providerType.
                      // If we have an appointmentId, we're continuing an existing appointment
                      if (appointmentId == null) {
                        requestProvider.createRequest(
                          PatientRequest(
                            patientId: uid,
                            requestType: RequestType.consult,
                            urgency: urgency,
                            category: category['title']!,
                            providerType: requestProvider.providerType,
                          ),
                        );
                      }

                      // Check if this is an immediate appointment check-in
                      if (chatMode == ChatMode.immediate &&
                          appointmentId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ChatInterface(
                                  isSynchronous: true,
                                  isImmediate: true,
                                  urgency: urgency,
                                  appointmentId: appointmentId,
                                  category: category['title']!,
                                ),
                          ),
                        );
                        return;
                      }

                      // Otherwise, follow the normal flow based on urgency
                      if (urgency.toLowerCase() == "quick") {
                        // For quick consults, navigate to ProviderListScreen.
                        Provider.of<ProviderProvider>(
                          context,
                          listen: false,
                        ).loadProviders(requestProvider.providerType);

                        // Pass the category and isUrgent flag to ProviderListScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ProviderListScreen(
                                  category: category['title']!,
                                  isUrgent: true,
                                ),
                          ),
                        );
                      } else {
                        // For routine consults, navigate directly to SchedulingScreen.
                        // We need to set selectedProvider to null since no provider was selected yet
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => SchedulingScreen(
                                  category: category['title']!,
                                  isUrgent: false,
                                  selectedProvider: null,
                                ),
                          ),
                        );
                      }
                    },
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                category['title']!,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Flexible(
                              child: Text(
                                category['description']!,
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
