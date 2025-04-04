// lib/screens/patient/category_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/patient_request.dart';
import '../../models/chat_mode.dart';
import '../../providers/request_provider.dart';
import '../../providers/provider_provider.dart';
import '../../utils/categories.dart';
import '../../theme.dart';
import './provider_bottom_sheet.dart';
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
    // Get provider type directly from the provider
    final requestProvider = Provider.of<RequestProvider>(
      context,
      listen: false,
    );
    final providerType = requestProvider.providerType;

    // Log which provider type is being used for clarity
    debugPrint(
      'DEBUG: CategorySelectionScreen using provider type: ${providerType.name}',
    );

    final List<Map<String, dynamic>> categories =
        providerType == ProviderType.medicalProvider
            ? medicalProviderCategories
            : physicalTherapistCategories;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Choose a Category"),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What brings you in today?",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Select the category that best describes your symptoms",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodyLarge?.color?.withAlpha(180),
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
                padding: const EdgeInsets.only(bottom: 16),
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
                      requestProvider.setCategory(category['title']!);
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
                        // For quick consults, load providers and show bottom sheet
                        Provider.of<ProviderProvider>(
                          context,
                          listen: false,
                        ).loadProviders(requestProvider.providerType);

                        // Show the provider bottom sheet
                        ProviderBottomSheet.show(
                          context,
                          category['title']!,
                          true, // isUrgent = true
                        );
                      } else {
                        // For routine consults, either show provider selection or go directly to scheduling
                        if (requestProvider.providerType ==
                            ProviderType.medicalProvider) {
                          // For medical providers, show the provider selection first
                          ProviderBottomSheet.show(
                            context,
                            category['title']!,
                            false, // isUrgent = false
                          );
                        } else {
                          // For other types, go directly to scheduling
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
                      }
                    },
                    child: Card(
                      elevation: 2,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(26),
                          width: 1,
                        ),
                      ),
                      child:
                          category['imagePath'] != null
                              ? Stack(
                                children: [
                                  // Background image with opacity
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Opacity(
                                        opacity:
                                            0.3, // Slightly higher opacity (was 0.2)
                                        child: Image.asset(
                                          category['imagePath'],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Content
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        // Remove icon and just show larger text
                                        Text(
                                          category['title']!,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.copyWith(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 24,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.visible,
                                        ),
                                        const SizedBox(height: 8),
                                        // Bottom highlight bar
                                        Container(
                                          height: 4,
                                          width: 40,
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary.withAlpha(77),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                              : Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Remove icon and just show larger text
                                    Text(
                                      category['title']!,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.visible,
                                    ),
                                    const SizedBox(height: 8),
                                    // Bottom highlight bar
                                    Container(
                                      height: 4,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withAlpha(77),
                                        borderRadius: BorderRadius.circular(2),
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
