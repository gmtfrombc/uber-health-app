// lib/screens/voice_chat_interface_screen.dart
import 'package:flutter/material.dart';
import 'package:uber_health_app/widgets/animated_consultation_screen.dart';

class VoiceChatInterfaceScreen extends StatefulWidget {
  final bool isSynchronous;
  final bool isImmediate;
  final String urgency;
  const VoiceChatInterfaceScreen({
    super.key,
    required this.isSynchronous,
    required this.isImmediate,
    required this.urgency,
  });

  @override
  State<VoiceChatInterfaceScreen> createState() =>
      _VoiceChatInterfaceScreenState();
}

class _VoiceChatInterfaceScreenState extends State<VoiceChatInterfaceScreen> {
  // Placeholder state for voice chat.
  // Integrate Eleven Labs TTS and a speech-to-text package here as needed.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Chat with Triage Assistant')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Voice Chat Interface Placeholder'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // After completing voice chat, navigate to Animated Consultation Screen.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => const AnimatedConsultationScreen(
                          isSynchronous: true,
                          isImmediate: false,
                          urgency: "Routine", // Adjust as needed.
                        ),
                  ),
                );
              },
              child: const Text('Finish Voice Chat'),
            ),
          ],
        ),
      ),
    );
  }
}
