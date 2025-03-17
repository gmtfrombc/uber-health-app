// lib/screens/request_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/patient_request.dart';
import '../providers/request_provider.dart';
import 'chat_interface.dart';
import 'category_selection_screen.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  int selectedToggleIndex = 0; // 0: Medical Provider, 1: Physical Therapist

  @override
  void initState() {
    super.initState();
    // Clear previous conversation data after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RequestProvider>(context, listen: false).clearRequest();
      // Set the default provider type to Medical Provider.
      Provider.of<RequestProvider>(
        context,
        listen: false,
      ).setProviderType(ProviderType.medicalProvider);
    });
  }

  // Helper method to create a tile.
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
          // For consults, default category is "Other". For medical questions, it's "Medical Question".
          String category =
              type == RequestType.consult ? "Other" : "Medical Question";
          final providerType =
              Provider.of<RequestProvider>(context, listen: false).providerType;
          Provider.of<RequestProvider>(context, listen: false).createRequest(
            PatientRequest(
              patientId: uid,
              requestType: type,
              urgency: urgency,
              category: category,
              providerType: providerType,
            ),
          );
          if (type == RequestType.consult) {
            // Navigate to CategorySelectionScreen, passing the chosen urgency ("Quick" or "Routine").
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategorySelectionScreen(urgency: urgency),
              ),
            );
          } else {
            // For medical questions, set category and navigate directly to ChatInterface.
            Provider.of<RequestProvider>(
              context,
              listen: false,
            ).setCategory("Medical Question");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => const ChatInterface(
                      isSynchronous: false,
                      isImmediate: true, // For testing; adjust as needed.
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
    // Toggle button widget for provider type selection.
    Widget providerToggle() {
      final requestProvider = Provider.of<RequestProvider>(
        context,
        listen: false,
      );
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Provider Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ToggleButtons(
              isSelected: [
                requestProvider.providerType == ProviderType.medicalProvider,
                requestProvider.providerType == ProviderType.physicalTherapist,
              ],
              onPressed: (int index) {
                setState(() {
                  selectedToggleIndex = index;
                  final newType =
                      index == 0
                          ? ProviderType.medicalProvider
                          : ProviderType.physicalTherapist;
                  requestProvider.setProviderType(newType);
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Medical Provider'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Physical Therapist'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Request Consult')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            providerToggle(),
            // Consultation Options
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Consultation Options',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            // Quick Consult tile (urgency: "Quick")
            buildTile(
              context: context,
              type: RequestType.consult,
              urgency: 'Quick',
              title: 'Quick Consult',
              timing: 'Less than 5 minutes',
              price: '\$90',
            ),
            // Routine Consult tile (urgency: "Routine")
            buildTile(
              context: context,
              type: RequestType.consult,
              urgency: 'Routine',
              title: 'Routine Consult',
              timing: '12-24 hours',
              price: '\$70',
            ),
            const Divider(height: 40, thickness: 2),
            // Medical Question tile (only one option)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Medical Questions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            buildTile(
              context: context,
              type: RequestType.medicalQuestion,
              urgency: 'Routine',
              title: 'Routine Medical Question',
              timing: '12-24 hours',
              price: '\$70',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
