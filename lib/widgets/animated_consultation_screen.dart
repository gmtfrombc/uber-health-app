// lib/widgets/animated_consultation_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../screens/home_screen.dart';
import '../screens/final_screen.dart';
import '../models/message.dart';
import '../providers/request_provider.dart';
import '../services/chatgpt_service.dart';

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
    // Configure the animations and messages based on flow
    if (widget.isImmediate) {
      // Immediate flows:
      if (widget.isSynchronous) {
        // Quick Consult: 4-stage flow
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
        // Quick Medical Question: 3-stage flow (omit connecting stage)
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
      // Both consult and medical question flows use a 2-stage sequence here.
      animations = [
        'assets/animations/doctor_request.json',
        'assets/animations/doctor_connected.json',
      ];
      if (widget.isSynchronous) {
        // For consults
        if (widget.urgency.toLowerCase() == 'routine') {
          messages = [
            'Reading your request',
            'Your request has been received, we will notify you by text when your provider is ready (expect 30-60 minutes). Please be ready to connect within 5 minutes of the notification.',
          ];
        } else if (widget.urgency.toLowerCase() == 'no rush') {
          messages = [
            'Reading your request',
            'Your request has been received, we will notify you by text when your provider is ready (expect 12-24 hours). Please be ready to connect within 5 minutes of the notification.',
          ];
        } else {
          messages = [
            'Reading your request',
            'Your request has been received, we will notify you by text when your provider is ready.',
          ];
        }
      } else {
        // For medical questions
        if (widget.urgency.toLowerCase() == 'routine') {
          messages = [
            'Reading your request',
            'Your request has been received, we will notify you by text when the provider has responded to your request (expect 30-60 minutes).',
          ];
        } else if (widget.urgency.toLowerCase() == 'no rush') {
          messages = [
            'Reading your request',
            'Your request has been received, we will notify you by text when the provider has responded to your request (expect 12-24 hours).',
          ];
        } else {
          messages = [
            'Reading your request',
            'Your request has been received, we will notify you by text when the provider has responded to your request.',
          ];
        }
      }
    }
    // Start the animation sequence and summary generation concurrently.
    animateStages();
    if (widget.isImmediate) {
      _generateSummary(); // Only generate summary automatically for immediate flows.
    }
  }

  Future<void> animateStages() async {
    if (!widget.isImmediate) {
      // Non-immediate flows: auto advance the first stage, then remain on the final stage (with a "Got it!" button).
      setState(() {
        currentStage = 0;
      });
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      setState(() {
        currentStage = animations.length - 1;
      });
      // Remain on final stage; user can tap "Got it!" to finish.
    } else {
      // Immediate flows: auto-advance through all stages.
      for (int i = 0; i < animations.length; i++) {
        if (!mounted) return;
        setState(() {
          currentStage = i;
        });
        await Future.delayed(const Duration(seconds: 3));
      }
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FinalScreen(isSynchronous: widget.isSynchronous),
        ),
      );
    }
  }

  Future<void> _generateSummary() async {
    // Retrieve the saved conversation from RequestProvider.
    final requestProvider = Provider.of<RequestProvider>(
      context,
      listen: false,
    );
    final conversationMessages = requestProvider.conversation;
    if (conversationMessages == null) return;

    // Build conversation for summarization.
    List<Map<String, String>> conversation =
        conversationMessages.map((m) {
          return {
            "role": m.sender == 'patient' ? "user" : "assistant",
            "content": m.content,
          };
        }).toList();
    // Prepend a system prompt specifically for summarization.
    conversation.insert(0, {
      "role": "system",
      "content": "Please summarize the following conversation concisely.",
    });

    try {
      String summary = await ChatGPTService().getAIResponse(conversation);
      // Append the summary as a new message to the conversation.
      requestProvider.updateConversation([
        ...conversationMessages,
        Message(sender: 'ai', content: summary, timestamp: DateTime.now()),
      ]);
    } catch (e) {
      debugPrint("Error generating summary: $e");
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
