// lib/widgets/animated_consultation_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../providers/request_provider.dart';
import '../providers/provider_provider.dart';
import '../services/chatgpt_service.dart';
import '../utils/prompts.dart';
import '../screens/consultation/final_screen.dart';
import '../theme.dart';
import '../screens/main_screen.dart';

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
  List<String> animations = [];
  List<String> messages = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final providerProvider = Provider.of<ProviderProvider>(
        context,
        listen: false,
      );
      final requestProvider = Provider.of<RequestProvider>(
        context,
        listen: false,
      );
      final selectedProvider = providerProvider.selectedProvider;

      String providerName = "your provider";
      if (selectedProvider != null) {
        // Format as "Dr. LastName" if credentials include MD, otherwise "FirstName LastName, Credentials"
        if (selectedProvider.credentials?.toLowerCase().contains('md') ==
            true) {
          providerName = "Dr. ${selectedProvider.lastname}";
        } else if (selectedProvider.credentials?.isNotEmpty == true) {
          providerName =
              "${selectedProvider.firstname} ${selectedProvider.lastname}, ${selectedProvider.credentials}";
        } else {
          providerName =
              "${selectedProvider.firstname} ${selectedProvider.lastname}";
        }
      } else if (requestProvider.currentRequest?.providerId != null) {
        // If we have a providerId in the request but no selected provider, use generic text
        providerName = "your assigned provider";
      }

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
          'Connecting you with $providerName',
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
            'Connecting you with $providerName',
          ];
        } else if (widget.urgency.toLowerCase() == 'routine') {
          // Routine Consult (12-24 hours) non-immediate flow: 2-stage.
          animations = [
            'assets/animations/doctor_request.json',
            'assets/animations/doctor_connected.json',
          ];
          messages = [
            'Reading your request',
            'Your request has been received, we will notify you by text when $providerName is ready (expect 12-24 hours). Please be ready to connect within 5 minutes of the notification.',
          ];
        } else {
          // Fallback (should not occur)
          animations = [
            'assets/animations/doctor_request.json',
            'assets/animations/doctor_connected.json',
          ];
          messages = [
            'Reading your request',
            'Your request has been received.',
          ];
        }
      } else {
        // Medical Question flow: always non-immediate, 2-stage.
        animations = [
          'assets/animations/doctor_request.json',
          'assets/animations/doctor_connected.json',
        ];
        messages = [
          'Reading your request',
          'Your request has been received, we will notify you by text when $providerName has responded to your question (expect 12-24 hours).',
        ];
      }

      // Start animation after we've set up the messages
      animateStages();

      // For immediate consults or checked-in appointments, generate the summary
      if ((widget.isImmediate && widget.isSynchronous) ||
          widget.appointmentId != null) {
        _generateSummary();
      }
    });
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
      appBar: AppBar(
        title: const Text('Processing Request'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryLightColor.withOpacity(0.1),
                      AppTheme.backgroundColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Lottie.asset(
                    animations.isNotEmpty
                        ? animations[currentStage]
                        : 'assets/animations/doctor_request.json',
                    width: 200,
                    height: 200,
                    repeat: true,
                    frameRate: FrameRate.max,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  messages.isNotEmpty
                      ? messages[currentStage]
                      : "Processing your request...",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (!widget.isImmediate && currentStage == animations.length - 1)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const MainScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Got it!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
