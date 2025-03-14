// lib/screens/summary_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart'; // Ensure you have this import to navigate to HomeScreen

class SummaryDetailScreen extends StatelessWidget {
  final String conversationId;
  const SummaryDetailScreen({super.key, required this.conversationId});

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
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String summary =
              data['aiTriageSummary'] ?? "No summary provided.";
          DateTime? createdAt;
          if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
            createdAt = (data['createdAt'] as Timestamp).toDate();
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (createdAt != null)
                    Text(
                      'Date: ${createdAt.toLocal().toString().substring(0, 16)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(summary, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 80), // extra spacing for bottom button
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
          child: const Text('Start Meeting'),
        ),
      ),
    );
  }
}
