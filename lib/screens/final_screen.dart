// lib/screens/final_screen.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class FinalScreen extends StatelessWidget {
  final bool isSynchronous;

  const FinalScreen({required this.isSynchronous, super.key});

  @override
  Widget build(BuildContext context) {
    String finalMessage;
    String buttonText;
    if (isSynchronous) {
      finalMessage = 'You are connected to Dr. Tolson';
      buttonText = 'Start Consultation';
    } else {
      finalMessage = 'Dr. Tolson has responded to your message';
      buttonText = 'Read Message';
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Connected')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/doctor_connected.json',
              width: 200,
              height: 200,
              repeat: true,
            ),
            const SizedBox(height: 20),
            Text(
              finalMessage,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Define what should happen next.
              },
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
