// lib/screens/summary_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SummaryScreen extends StatelessWidget {
  final String conversationId;
  const SummaryScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Triage Summary')),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance
                .collection('conversations')
                .doc(conversationId)
                .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No conversation found.'));
          }
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          String summary = data['aiTriageSummary'] ?? "No summary provided.";
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(summary, style: const TextStyle(fontSize: 16)),
          );
        },
      ),
    );
  }
}
