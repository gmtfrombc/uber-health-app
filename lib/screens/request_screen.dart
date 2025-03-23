// lib/screens/request_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/patient_request.dart';
import '../models/chat_mode.dart'; // Import the common ChatMode
import '../providers/request_provider.dart';
import 'chat_interface.dart';
import 'category_selection_screen.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({Key? key}) : super(key: key);

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  int selectedProviderToggleIndex = 0; // 0: Medical, 1: Physical Therapist
  ChatMode selectedChatMode = ChatMode.regular;

  @override
  void initState() {
    super.initState();
    // Clear any previous request and set default provider type.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final requestProvider = Provider.of<RequestProvider>(
        context,
        listen: false,
      );
      requestProvider.clearRequest();
      requestProvider.setProviderType(ProviderType.medicalProvider);
    });
  }

  // Provider type toggle widget.
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
                selectedProviderToggleIndex = index;
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

  // Chat mode toggle widget.
  Widget chatModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Chat Mode',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ToggleButtons(
            isSelected: [
              selectedChatMode == ChatMode.regular,
              selectedChatMode == ChatMode.voice,
            ],
            onPressed: (int index) {
              setState(() {
                selectedChatMode =
                    index == 0 ? ChatMode.regular : ChatMode.voice;
              });
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Regular Chat'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Voice Chat'),
              ),
            ],
          ),
        ],
      ),
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
            // Navigate to CategorySelectionScreen, passing the selected chat mode.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => CategorySelectionScreen(
                      urgency: urgency,
                      chatMode: selectedChatMode,
                    ),
              ),
            );
          } else {
            // For questions, navigate directly to ChatInterface.
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
      appBar: AppBar(title: const Text('Request Consult / Question')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            providerToggle(),
            chatModeToggle(),
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
              timing: 'Less than 5 minutes',
              price: '\$90',
            ),
            // Routine Consult Option
            buildTile(
              context: context,
              type: RequestType.consult,
              urgency: 'Routine',
              title: 'Routine Consult',
              timing: '12-24 hours',
              price: '\$70',
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
