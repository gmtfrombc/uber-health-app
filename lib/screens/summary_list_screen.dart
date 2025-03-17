// lib/screens/summary_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'summary_detail_screen.dart';
import '../services/firebase_service.dart';

class SummaryListScreen extends StatelessWidget {
  const SummaryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get current user's UID from FirebaseAuth
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Query the 'conversations' collection for documents belonging to this user,
    // ordered by createdAt descending.
    final Stream<QuerySnapshot> summariesStream =
        FirebaseFirestore.instance
            .collection('conversations')
            .where('patientId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('AI Summaries')),
      body: StreamBuilder<QuerySnapshot>(
        stream: summariesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading summaries: ${snapshot.error}'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter documents to only include those with a non-empty aiTriageSummary.
          final docs = snapshot.data?.docs ?? [];
          final validDocs =
              docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final summary = data['aiTriageSummary'];
                return summary != null &&
                    summary is String &&
                    summary.trim().isNotEmpty;
              }).toList();

          if (validDocs.isEmpty) {
            return const Center(child: Text('No summaries available.'));
          }
          return ListView.builder(
            itemCount: validDocs.length,
            itemBuilder: (context, index) {
              final doc = validDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final Timestamp timestamp = data['createdAt'] as Timestamp;
              final DateTime createdAt = timestamp.toDate();
              final String summary = data['aiTriageSummary'];
              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  try {
                    await FirebaseService().deleteConversation(doc.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Summary deleted")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error deleting summary: $e")),
                    );
                  }
                },
                child: ListTile(
                  title: Text(
                    'Summary from ${createdAt.toLocal().toString().substring(0, 16)}',
                  ),
                  subtitle: Text(
                    summary.length > 50
                        ? '${summary.substring(0, 50)}...'
                        : summary,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => SummaryDetailScreen(conversationId: doc.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
