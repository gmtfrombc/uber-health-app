// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/request_screen.dart';
import '../screens/summary_screen.dart';
import '../widgets/app_drawer.dart';
import '../providers/request_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access RequestProvider to check for a conversation ID
    final requestProvider = Provider.of<RequestProvider>(
      context,
      listen: false,
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Uber Health'),
        backgroundColor: Colors.teal,
      ),
      // Use endDrawer to place the drawer on the right side
      endDrawer: const AppDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Button to navigate to the Request Screen
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 30,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Request a Consult',
                style: TextStyle(fontSize: 18),
              ),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RequestScreen()),
                  ),
            ),
            const SizedBox(height: 20),
            // Button to view the AI triage summary
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 30,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'View AI Summary',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () {
                if (requestProvider.lastConversationId != null) {
                  // Navigate to SummaryScreen if a conversation ID exists
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => SummaryScreen(
                            conversationId: requestProvider.lastConversationId!,
                          ),
                    ),
                  );
                } else {
                  // Otherwise, show an alert dialog notifying no summary is available
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('No Summary Available'),
                          content: const Text(
                            'There is no conversation summary to display. '
                            'Please complete a conversation first.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
