// lib/screens/video_call/voice_chat_interface_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voice_chat_core/voice_chat_core.dart' as core;

import '../../models/message.dart' as app_message;
import '../../models/patient_request.dart';
import '../../providers/request_provider.dart';
import '../../services/chatgpt_service.dart';
import '../../services/firebase_service.dart';
import '../../providers/medical_questions_provider.dart';
import '../../screens/main_screen.dart';
import '../../widgets/animated_message_bubble.dart';
import '../../widgets/consistent_app_bar.dart';
import '../../widgets/animated_consultation_screen.dart';
import '../../utils/prompts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VoiceChatInterfaceScreen extends StatefulWidget {
  final bool isSynchronous; // true for consult, false for medical question
  final bool isImmediate; // quick vs routine
  final String urgency; // "Quick" or "Routine"
  final String? appointmentId; // if linked to appointment
  final String? category;

  const VoiceChatInterfaceScreen({
    super.key,
    required this.isSynchronous,
    required this.isImmediate,
    required this.urgency,
    this.appointmentId,
    this.category,
  });

  @override
  State<VoiceChatInterfaceScreen> createState() =>
      _VoiceChatInterfaceScreenState();
}

class _VoiceChatInterfaceScreenState extends State<VoiceChatInterfaceScreen> {
  late core.SpeechService _speechService;
  late StreamSubscription _stateSubscription;
  late StreamSubscription _messageSubscription;
  StreamSubscription? _soundLevelSubscription;

  core.SpeechServiceState _currentVoiceState = core.SpeechServiceState.idle;

  final List<core.Message> _messages = [];

  bool _isGeneratingSummary = false;
  bool _isFirstInteraction = true;

  final ScrollController _scrollController = ScrollController();

  String _systemPrompt = "";
  final ChatGPTService _chatGPTService = ChatGPTService();

  final double _soundLevel = 0.0; // 0.0 – 1.0

  @override
  void initState() {
    super.initState();

    _speechService = Provider.of<core.SpeechService>(context, listen: false);

    _initializeConversation();

    _stateSubscription = _speechService.onStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _currentVoiceState = state;
      });
    });

    _messageSubscription = _speechService.onMessageReceived.listen((message) {
      if (!mounted) return;
      setState(() {
        int idx = _messages.indexWhere((m) => m.id == message.id);
        if (idx != -1) {
          _messages[idx] = message;
        } else {
          _messages.add(message);
        }
      });
      _scrollToBottom();
    });

    // TODO: Hook up a real sound-level stream from SpeechService when available.
  }

  void _initializeConversation() {
    // Reset conversation each time to avoid duplicates
    _speechService.resetConversation();

    final requestProvider = Provider.of<RequestProvider>(
      context,
      listen: false,
    );
    final currentRequest = requestProvider.currentRequest;

    String category = "";
    String initialPrompt;

    final RequestType requestType =
        currentRequest?.requestType ??
        (widget.isSynchronous
            ? RequestType.consult
            : RequestType.medicalQuestion);

    if (requestType == RequestType.medicalQuestion) {
      _systemPrompt = medicalQuestionPrompt;
      initialPrompt = providerPromptQuestion;
    } else {
      if (widget.category != null) {
        category = widget.category!;
        initialPrompt = getInitialPrompt(
          requestProvider.providerType,
          requestType,
        );
      } else if (requestProvider.selectedCategory != null) {
        category = requestProvider.selectedCategory!;
        initialPrompt = getInitialPrompt(
          requestProvider.providerType,
          requestType,
        );
      } else if (currentRequest != null) {
        category = currentRequest.category;
        initialPrompt = getInitialPrompt(
          currentRequest.providerType,
          currentRequest.requestType,
        );
      } else {
        initialPrompt = defaultPrompt;
        category = "Other";
      }

      initialPrompt =
          "Hi, I'm your virtual medical assistant. Tap the microphone and tell me about your symptoms.";
      _systemPrompt = getComplaintPrompt(
        requestProvider.providerType,
        category,
      );
    }

    _speechService.setSystemPrompt(_systemPrompt);

    _messages.add(
      core.Message(
        isUser: false,
        content: initialPrompt,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _stateSubscription.cancel();
    _messageSubscription.cancel();
    _soundLevelSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleMic() {
    if (_currentVoiceState == core.SpeechServiceState.listening) {
      _speechService.stopListening();
    } else if (_currentVoiceState == core.SpeechServiceState.speaking) {
      _speechService.stopSpeaking();
    } else if (_currentVoiceState == core.SpeechServiceState.idle) {
      if (_isFirstInteraction) {
        _isFirstInteraction = false;
        _speechService.initiateVoiceFlow();
      } else {
        _speechService.startListening();
      }
    }
  }

  Future<void> _handleDone() async {
    setState(() => _isGeneratingSummary = true);

    List<Map<String, String>> conversation =
        _messages.map((m) {
          return {
            "role": m.isUser ? "user" : "assistant",
            "content": m.content,
          };
        }).toList();

    final requestProvider = Provider.of<RequestProvider>(
      context,
      listen: false,
    );
    final isMedicalQuestion =
        widget.isSynchronous != true &&
        (requestProvider.currentRequest?.requestType ==
            RequestType.medicalQuestion);

    if (isMedicalQuestion) {
      conversation.insert(0, {
        "role": "system",
        "content": medicalQuestionSummaryPrompt,
      });
    } else {
      conversation.insert(0, {"role": "system", "content": triagePrompt});
    }

    try {
      final summary = await _chatGPTService.getAIResponse(conversation);

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("User not authenticated");

      // Ensure conversation saved
      if (requestProvider.conversation == null) {
        List<app_message.Message> appMessages =
            _messages
                .map(
                  (m) => app_message.Message(
                    sender: m.isUser ? 'patient' : 'ai',
                    content: m.content,
                    timestamp: m.timestamp,
                  ),
                )
                .toList();
        await requestProvider.updateConversation(appMessages);
      }

      if (widget.appointmentId != null) {
        await FirebaseService().updatePatientRequest(widget.appointmentId!, {
          'aiTriageSummary': summary,
          'status': 'triaged',
        });
      } else {
        final Map<String, dynamic> additionalData =
            isMedicalQuestion ? {'status': 'pending'} : {};
        final conversationId = await requestProvider
            .updateConversationWithSummary(summary, additionalData);
        if (conversationId == null) throw Exception("Failed to save summary");
        if (isMedicalQuestion && mounted) {
          Provider.of<MedicalQuestionsProvider>(
            context,
            listen: false,
          ).refreshQuestions();
        }
      }

      if (!mounted) return;
      setState(() => _isGeneratingSummary = false);

      if (isMedicalQuestion) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Your question has been submitted. A provider will respond soon.",
            ),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => AnimatedConsultationScreen(
                  isSynchronous: widget.isSynchronous,
                  isImmediate: widget.isImmediate,
                  urgency: widget.urgency,
                  appointmentId: widget.appointmentId,
                ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isGeneratingSummary = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Large visual indicator shown in the centre of the screen
  Widget _buildVoiceIndicator() {
    switch (_currentVoiceState) {
      case core.SpeechServiceState.listening:
        return _PulseBall(
          colors: [
            Theme.of(
              context,
            ).colorScheme.primary.withAlpha((0.6 * 255).round()),
            Theme.of(context).colorScheme.primary,
          ],
          size: 160,
          level: _soundLevel,
        );
      case core.SpeechServiceState.speaking:
        return _PulseBall(
          colors: [
            Theme.of(
              context,
            ).colorScheme.secondary.withAlpha((0.6 * 255).round()),
            Theme.of(context).colorScheme.secondary,
          ],
          size: 160,
          level: 0.2, // idle pulsing small
        );
      case core.SpeechServiceState.processing:
        // Show a muted pulse ball instead of progress indicator
        return _PulseBall(
          colors: [
            Theme.of(
              context,
            ).colorScheme.primary.withAlpha((0.2 * 255).round()),
            Theme.of(
              context,
            ).colorScheme.primary.withAlpha((0.4 * 255).round()),
          ],
          size: 160,
          level: 0.1,
        );
      case core.SpeechServiceState.idle:
        // Neutral pulse ball inviting the user to begin
        return _PulseBall(
          colors: [
            Theme.of(
              context,
            ).colorScheme.primary.withAlpha((0.3 * 255).round()),
            Theme.of(
              context,
            ).colorScheme.primary.withAlpha((0.6 * 255).round()),
          ],
          size: 160,
          level: 0.1,
        );
    }
  }

  String _stateLabel() {
    switch (_currentVoiceState) {
      case core.SpeechServiceState.listening:
        return 'Speak';
      case core.SpeechServiceState.speaking:
        return 'Listen';
      default:
        return '';
    }
  }

  // Small clickable mic control in the bottom controls row
  Widget _buildMicButton() {
    IconData icon;
    Color color = Theme.of(context).colorScheme.primary;
    VoidCallback? action;

    switch (_currentVoiceState) {
      case core.SpeechServiceState.listening:
        icon = Icons.stop_circle_rounded;
        color = Colors.red;
        action = () => _speechService.stopListening();
        break;
      case core.SpeechServiceState.speaking:
        icon = Icons.stop_circle_rounded;
        color = Theme.of(context).colorScheme.secondary;
        action = () => _speechService.stopSpeaking();
        break;
      case core.SpeechServiceState.processing:
        return IconButton(
          iconSize: 48,
          onPressed: null,
          icon: Icon(Icons.mic, color: Theme.of(context).disabledColor),
        );
      case core.SpeechServiceState.idle:
        icon = Icons.mic;
        color = Theme.of(context).colorScheme.primary;
        action = _toggleMic;
        break;
    }

    return IconButton(
      iconSize: 48,
      color: color,
      onPressed: action,
      icon: Icon(icon),
    );
  }

  Widget _buildMessageBubble(core.Message message) {
    final appMessage = app_message.Message(
      sender: message.isUser ? 'patient' : 'ai',
      content: message.content,
      timestamp: message.timestamp,
    );

    bool shouldAnimate = !message.isUser && _messages.indexOf(message) == 0;
    return AnimatedMessageBubble(message: appMessage, animate: shouldAnimate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bool isTriageComplete =
        _messages.isNotEmpty &&
        !_messages.last.isUser &&
        _messages.last.content.contains("[TRIAGE_COMPLETE]");

    return Scaffold(
      appBar: ConsistentAppBar(title: 'Voice Assistant'),
      body: Column(
        children: [
          Expanded(
            child:
                isTriageComplete
                    ? Builder(
                      builder: (context) {
                        final visibleMessages =
                            _messages.where((m) {
                              final lc = m.content.toLowerCase();
                              return !lc.contains('triage complete') &&
                                  !lc.contains('[triage_complete]');
                            }).toList();
                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8),
                          itemCount: visibleMessages.length,
                          itemBuilder:
                              (context, index) =>
                                  _buildMessageBubble(visibleMessages[index]),
                        );
                      },
                    )
                    : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildVoiceIndicator(),
                          const SizedBox(height: 16),
                          if (_stateLabel().isNotEmpty)
                            Text(
                              _stateLabel(),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
          ),

          if (_isGeneratingSummary)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircularProgressIndicator(color: theme.colorScheme.primary),
                  const SizedBox(height: 8),
                  const Text('Generating summary...'),
                ],
              ),
            ),

          // Bottom controls
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hint label when conversation not started yet
                if (!isTriageComplete &&
                    _currentVoiceState == core.SpeechServiceState.idle &&
                    _isFirstInteraction)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Click the mic to start the conversation',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                if (!isTriageComplete) _buildMicButton(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isTriageComplete ? _handleDone : null,
                    style: theme.elevatedButtonTheme.style?.copyWith(
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseBall extends StatefulWidget {
  final List<Color> colors; // gradient colors (start -> end)
  final double size;
  final double level; // 0–1 amplitude
  const _PulseBall({required this.colors, this.size = 160, this.level = 0});

  @override
  State<_PulseBall> createState() => _PulseBallState();
}

class _PulseBallState extends State<_PulseBall>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dynamicScale = 1 + (_controller.value * 0.15) + (widget.level * 0.35);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: dynamicScale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: widget.colors),
            ),
          ),
        );
      },
    );
  }
}
