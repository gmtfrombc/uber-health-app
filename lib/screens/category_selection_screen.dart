// lib/screens/category_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/patient_request.dart';
import '../models/chat_mode.dart'; // Import the common ChatMode
import '../providers/request_provider.dart';
import '../providers/provider_provider.dart';
import '../utils/categories.dart';
import 'provider_list_screen.dart';
import 'scheduling_screen.dart';

class CategorySelectionScreen extends StatelessWidget {
  final String urgency;
  final ChatMode chatMode;
  const CategorySelectionScreen({
    Key? key,
    required this.urgency,
    required this.chatMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final providerType =
        Provider.of<RequestProvider>(context, listen: false).providerType;
    final List<Map<String, String>> categories =
        providerType == ProviderType.medicalProvider
            ? medicalProviderCategories
            : physicalTherapistCategories;

    return Scaffold(
      appBar: AppBar(title: const Text("Choose Problem")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: List.generate(categories.length, (index) {
            final category = categories[index];
            return GestureDetector(
              onTap: () {
                final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                final requestProvider = Provider.of<RequestProvider>(
                  context,
                  listen: false,
                );
                // Set the selected category.
                requestProvider.setCategory(category['title']!);
                // Create a new PatientRequest with the required providerType.
                requestProvider.createRequest(
                  PatientRequest(
                    patientId: uid,
                    requestType: RequestType.consult,
                    urgency: urgency,
                    category: category['title']!,
                    providerType: requestProvider.providerType,
                  ),
                );
                // Determine navigation based on urgency.
                if (urgency.toLowerCase() == "quick") {
                  // For quick consults, navigate to ProviderListScreen.
                  Provider.of<ProviderProvider>(
                    context,
                    listen: false,
                  ).loadProviders(requestProvider.providerType);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderListScreen(urgency: urgency),
                    ),
                  );
                } else {
                  // For routine consults, navigate directly to SchedulingScreen.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SchedulingScreen(urgency: "Routine"),
                    ),
                  );
                }
              },
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category['title']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category['description']!,
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
