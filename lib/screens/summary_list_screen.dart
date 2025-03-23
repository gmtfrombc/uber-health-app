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
    debugPrint('SummaryListScreen - Current user ID: $userId');

    if (userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Triage Summaries')),
        body: const Center(
          child: Text('You must be logged in to view summaries'),
        ),
      );
    }

    // Query the 'conversations' collection for documents belonging to this user,
    // ordered by createdAt descending.
    final Stream<QuerySnapshot> summariesStream =
        FirebaseFirestore.instance
            .collection('conversations')
            .where('patientId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('AI Triage Summaries')),
      body: StreamBuilder<QuerySnapshot>(
        stream: summariesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('SummaryListScreen Error: ${snapshot.error}');
            return Center(
              child: Text('Error loading summaries: ${snapshot.error}'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Log raw data for debugging
          final docs = snapshot.data?.docs ?? [];
          debugPrint(
            'SummaryListScreen - Found ${docs.length} documents in Firestore',
          );

          // Log details of each document for debugging
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final keys = data.keys.toList().join(', ');
            debugPrint(
              'Document ID: ${doc.id}, patientId: ${data['patientId']}, keys: $keys',
            );

            if (data.containsKey('aiTriageSummary')) {
              final summaryLength =
                  (data['aiTriageSummary'] as String?)?.length ?? 0;
              debugPrint('Summary length: $summaryLength characters');
            } else {
              debugPrint('No aiTriageSummary field found in this document');
            }

            if (data.containsKey('messages')) {
              final messagesCount = (data['messages'] as List?)?.length ?? 0;
              debugPrint('Messages count: $messagesCount');
            }
          }

          // If no documents found, show a helpful message
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No summaries available.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Return to previous screen
                    },
                    child: const Text('Create a new consultation'),
                  ),
                ],
              ),
            );
          }

          // Filter documents to only include those with a non-empty aiTriageSummary.
          final validDocs =
              docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final summary = data['aiTriageSummary'];
                return summary != null &&
                    summary is String &&
                    summary.trim().isNotEmpty;
              }).toList();

          debugPrint(
            'SummaryListScreen - Valid documents with summaries: ${validDocs.length}',
          );

          if (validDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No summaries available yet.'),
                  const Text('Please complete a consultation first.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Return to previous screen
                    },
                    child: const Text('Start a new consultation'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: validDocs.length,
            itemBuilder: (context, index) {
              final doc = validDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              // Handle missing timestamp
              DateTime createdAt;
              try {
                final timestamp = data['createdAt'] as Timestamp?;
                createdAt = timestamp?.toDate() ?? DateTime.now();
              } catch (e) {
                debugPrint('Error parsing timestamp: $e');
                createdAt = DateTime.now();
              }

              final String summary =
                  data['aiTriageSummary'] as String? ?? 'No summary available';
              final String category = data['category'] as String? ?? 'Unknown';

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
                child: Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      'Summary - $category',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          createdAt.toLocal().toString().substring(0, 16),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          summary.length > 100
                              ? '${summary.substring(0, 100)}...'
                              : summary,
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  SummaryDetailScreen(conversationId: doc.id),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
