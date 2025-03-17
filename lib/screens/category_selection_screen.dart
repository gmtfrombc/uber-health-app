// lib/screens/category_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/patient_request.dart';
import '../providers/request_provider.dart';
// Import categories lists from the new file.
import '../utils/categories.dart';
import 'chat_interface.dart';

class CategorySelectionScreen extends StatelessWidget {
  final String urgency;
  const CategorySelectionScreen({super.key, required this.urgency});

  @override
  Widget build(BuildContext context) {
    // Choose the categories based on the selected provider type.
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
                // Create a new request including the selected category and providerType.
                requestProvider.createRequest(
                  PatientRequest(
                    patientId: uid,
                    requestType: RequestType.consult,
                    urgency: urgency,
                    category: category['title']!,
                    providerType: requestProvider.providerType,
                  ),
                );
                // Navigate to the ChatInterface screen.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ChatInterface(
                          isSynchronous: true,
                          isImmediate: urgency.toLowerCase() == 'quick',
                          urgency: urgency,
                        ),
                  ),
                );
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
