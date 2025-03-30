// lib/widgets/animated_consultation_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../providers/request_provider.dart';
import '../services/chatgpt_service.dart';
import '../utils/prompts.dart';
import '../screens/patient/home_screen.dart';
import '../screens/consultation/final_screen.dart';

class AnimatedConsultationScreen extends StatefulWidget {
  final bool isSynchronous; // true for consult, false for medical question
  final bool
  isImmediate; // for consult: Quick = immediate; for medical question, always non-immediate
  final String
  urgency; // For consult: "Quick" or "Routine"; for medical question: "Routine"
  final String?
  appointmentId; // ID for scheduled appointments that are being checked into

  const AnimatedConsultationScreen({
    required this.isSynchronous,
    required this.isImmediate,
    required this.urgency,
    this.appointmentId,
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
    // If this is a checked-in appointment, use specific messaging
    if (widget.appointmentId != null) {
      animations = [
        'assets/animations/doctor_request.json',
        'assets/animations/doctor_review.json',
        'assets/animations/doctor_connecting.json',
      ];
      messages = [
        'Processing your check-in',
        'Provider is reviewing your information',
        'Connecting you with your provider',
      ];
    } else if (widget.isSynchronous) {
      // Consult flow.
      if (widget.urgency.toLowerCase() == 'quick') {
        // Quick Consult immediate flow: 4-stage.
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
      } else if (widget.urgency.toLowerCase() == 'routine') {
        // Routine Consult (12-24 hours) non-immediate flow: 2-stage.
        animations = [
          'assets/animations/doctor_request.json',
          'assets/animations/doctor_connected.json',
        ];
        messages = [
          'Reading your request',
          'Your request has been received, we will notify you by text when your provider is ready (expect 12-24 hours). Please be ready to connect within 5 minutes of the notification.',
        ];
      } else {
        // Fallback (should not occur)
        animations = [
          'assets/animations/doctor_request.json',
          'assets/animations/doctor_connected.json',
        ];
        messages = ['Reading your request', 'Your request has been received.'];
      }
    } else {
      // Medical Question flow: always non-immediate, 2-stage.
      animations = [
        'assets/animations/doctor_request.json',
        'assets/animations/doctor_connected.json',
      ];
      messages = [
        'Reading your request',
        'Your request has been received, we will notify you by text when the provider has responded to your question (expect 12-24 hours).',
      ];
    }
    animateStages();
    // For immediate consults or checked-in appointments, generate the summary
    if ((widget.isImmediate && widget.isSynchronous) ||
        widget.appointmentId != null) {
      _generateSummary();
    }
  }

  Future<void> animateStages() async {
    // For appointments, always use immediate flow behavior
    final bool useImmediateFlow =
        widget.isImmediate || widget.appointmentId != null;

    if (!useImmediateFlow) {
      // Non-immediate flows: auto advance first stage, then remain on final stage.
      setState(() {
        currentStage = 0;
      });
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      setState(() {
        currentStage = animations.length - 1;
      });
      // Wait for user action ("Got it!") before proceeding.
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
          builder:
              (_) => FinalScreen(
                isSynchronous: widget.isSynchronous,
                appointmentId: widget.appointmentId,
              ),
        ),
      );
    }
  }

  Future<void> _generateSummary() async {
    final requestProvider = Provider.of<RequestProvider>(
      context,
      listen: false,
    );
    final conversationMessages = requestProvider.conversation;
    if (conversationMessages == null) return;
    List<Map<String, String>> conversation =
        conversationMessages.map((m) {
          return {
            "role": m.sender == 'patient' ? "user" : "assistant",
            "content": m.content,
          };
        }).toList();
    conversation.insert(0, {"role": "system", "content": triagePrompt});
    try {
      String summary = await ChatGPTService().getAIResponse(conversation);
      requestProvider.updateConversationWithSummary(summary, {});
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
