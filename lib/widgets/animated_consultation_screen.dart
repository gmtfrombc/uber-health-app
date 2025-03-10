// lib/widgets/animated_consultation_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:lottie/lottie.dart';
import '../screens/final_screen.dart';
import '../screens/home_screen.dart';

class AnimatedConsultationScreen extends StatefulWidget {
  final bool
  isSynchronous; // true for consults (telehealth), false for medical questions (messaging)
  final bool isImmediate; // true if "Quick", false if Routine or No Rush
  final String urgency; // "Quick", "Routine", or "No Rush"

  const AnimatedConsultationScreen({
    required this.isSynchronous,
    required this.isImmediate,
    required this.urgency,
    super.key,
  });

  @override
  AnimatedConsultationScreenState createState() =>
      AnimatedConsultationScreenState();
}

class AnimatedConsultationScreenState
    extends State<AnimatedConsultationScreen> {
  int currentStage = 0;
  late List<String> animations;
  late List<String> messages;

  @override
  void initState() {
    super.initState();
    // Configure flows based on consult vs. medical question and urgency.
    if (widget.isImmediate) {
      // Immediate flows:
      if (widget.isSynchronous) {
        // Quick Consult: 4-stage flow.
        animations = [
          'assets/animations/doctor_request.json',
          'assets/animations/doctor_search.json',
          'assets/animations/doctor_review.json',
          'assets/animations/doctor_connecting.json',
        ];
        messages = [
          'Reading your request',
          'Contacting healthcare provider',
          'Provider is reviewing your request',
          'Connecting you with Dr. Tolson',
        ];
      } else {
        // Quick Medical Question: 3-stage flow (omit the "connecting" stage).
        animations = [
          'assets/animations/doctor_request.json',
          'assets/animations/doctor_search.json',
          'assets/animations/doctor_review.json',
        ];
        messages = [
          'Reading your request',
          'Contacting healthcare provider',
          'Provider is reviewing your request',
        ];
      }
    } else {
      // Non-immediate flows (Routine or No Rush):
      if (widget.isSynchronous) {
        // Consult (Routine/No Rush Consult): 2-stage flow.
        animations = [
          'assets/animations/doctor_request.json',
          'assets/animations/doctor_connected.json',
        ];
        String finalMessage;
        if (widget.urgency.toLowerCase() == 'routine') {
          finalMessage =
              'Your request has been received, we will notify you by text when your provider is ready (expect 30-60 minutes). Please be ready to connect within 5 minutes of the notification.';
        } else if (widget.urgency.toLowerCase() == 'no rush') {
          finalMessage =
              'Your request has been received, we will notify you by text when your provider is ready (expect 12-24 hours). Please be ready to connect within 5 minutes of the notification.';
        } else {
          finalMessage =
              'Your request has been received, we will notify you by text when your provider is ready.';
        }
        messages = ['Reading your request', finalMessage];
      } else {
        // Medical Question (Routine/No Rush): 2-stage flow.
        animations = [
          'assets/animations/doctor_request.json',
          'assets/animations/doctor_connected.json',
        ];
        String finalMessage;
        if (widget.urgency.toLowerCase() == 'routine') {
          finalMessage =
              'Your request has been received, we will notify you by text when the provider has responded to your request (expect 30-60 minutes).';
        } else if (widget.urgency.toLowerCase() == 'no rush') {
          finalMessage =
              'Your request has been received, we will notify you by text when the provider has responded to your request (expect 12-24 hours).';
        } else {
          finalMessage =
              'Your request has been received, we will notify you by text when the provider has responded to your request.';
        }
        messages = ['Reading your request', finalMessage];
      }
    }
    animateStages();
  }

  Future<void> animateStages() async {
    if (!widget.isImmediate) {
      // For non-immediate flows, auto-advance the first stage, then remain on the final stage.
      setState(() {
        currentStage = 0;
      });
      await Future.delayed(const Duration(seconds: 3));
      setState(() {
        currentStage = animations.length - 1; // final static stage with button.
      });
      // Do not auto-advance further; wait for user action.
    } else {
      // Immediate flows: auto-advance through all stages.
      for (int i = 0; i < animations.length; i++) {
        setState(() {
          currentStage = i;
        });
        await Future.delayed(const Duration(seconds: 3));
      }
      await Future.delayed(const Duration(seconds: 1));
      // Check if the widget is still mounted before using the context.
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FinalScreen(isSynchronous: widget.isSynchronous),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Processing Request')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              animations[currentStage],
              width: 200,
              height: 200,
              repeat: true,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                messages[currentStage],
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            // For non-immediate flows, if at the final stage, show "Got it!" button.
            if (!widget.isImmediate && currentStage == animations.length - 1)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Got it!'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
