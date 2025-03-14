// lib/screens/request_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/patient_request.dart';
import '../providers/request_provider.dart';
import '../screens/chat_interface.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  @override
  void initState() {
    super.initState();
    // Clear any previous conversation data so a new conversation is started.
    Provider.of<RequestProvider>(context, listen: false).clearRequest();
  }

  // A helper method to create a tile
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
          // Get the current user's UID and create a new request.
          final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
          Provider.of<RequestProvider>(context, listen: false).createRequest(
            PatientRequest(patientId: uid, requestType: type, urgency: urgency),
          );
          // Determine if this is a quick (immediate) request.
          bool isImmediate = urgency.toLowerCase() == 'quick';
          // For consults, we assume synchronous (telehealth); for questions, asynchronous.
          bool isSynchronous = type == RequestType.consult;

          // Navigate to the ChatInterface screen.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => ChatInterface(
                    isSynchronous: isSynchronous,
                    isImmediate: isImmediate,
                    urgency: urgency, // "Quick", "Routine", or "No Rush"
                  ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Consult')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Consultation Options',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            buildTile(
              context: context,
              type: RequestType.consult,
              urgency: 'Quick',
              title: 'Quick Consult',
              timing: 'Less than 5 minutes',
              price: '\$90',
            ),
            buildTile(
              context: context,
              type: RequestType.consult,
              urgency: 'Routine',
              title: 'Routine Consult',
              timing: '30-60 minutes',
              price: '\$70',
            ),
            buildTile(
              context: context,
              type: RequestType.consult,
              urgency: 'No Rush',
              title: 'No Rush Consult',
              timing: '12-24 hours',
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
            buildTile(
              context: context,
              type: RequestType.medicalQuestion,
              urgency: 'Quick',
              title: 'Quick Medical Question',
              timing: 'Less than 5 minutes',
              price: '\$70',
            ),
            buildTile(
              context: context,
              type: RequestType.medicalQuestion,
              urgency: 'Routine',
              title: 'Routine Medical Question',
              timing: '30-60 minutes',
              price: '\$50',
            ),
            buildTile(
              context: context,
              type: RequestType.medicalQuestion,
              urgency: 'No Rush',
              title: 'No Rush Medical Question',
              timing: '12-24 hours',
              price: '\$30',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}