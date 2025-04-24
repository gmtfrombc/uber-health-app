// lib/screens/consultation/chat_interface.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/message.dart'
    as app_message; // Import app's Message model with prefix
import '../../providers/request_provider.dart';
import '../../models/patient_request.dart';
import '../../services/chatgpt_service.dart'; // Keep for summary generation
import '../../utils/prompts.dart';
import '../../widgets/animated_consultation_screen.dart';
import '../../widgets/animated_message_bubble.dart';
import '../../widgets/consistent_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import '../../providers/medical_questions_provider.dart';
import '../../screens/main_screen.dart';
import 'package:voice_chat_core/voice_chat_core.dart' as core;
import 'dart:async';

class ChatInterface extends StatefulWidget {
  final bool isSynchronous; // true for consult, false for medical question
  final bool
  isImmediate; // For consult: Quick = immediate; for medical question, always immediate (or can adjust if needed)
  final String
  urgency; // For consult: "Quick" or "Routine"; for medical question: "Routine"
  final String?
  appointmentId; // ID for scheduled appointments that are being checked into
  final String?
  category; // Category of the consult, used to set the correct prompt

  const ChatInterface({
    required this.isSynchronous,
    required this.isImmediate,
    required this.urgency,
    this.appointmentId,
    this.category,
    super.key,
  });

  @override
  ChatInterfaceState createState() => ChatInterfaceState();
}

class ChatInterfaceState extends State<ChatInterface> {
  final TextEditingController _textController = TextEditingController();
  final List<core.Message> _messages = []; // Use package's Message type
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingAI = false; // Used by voice service listener now
  bool _isGeneratingSummary = false;
  String _systemPrompt = "";
  final ChatGPTService _chatGPTService = ChatGPTService(); // Keep for summary

  // Voice Service related state
  late core.SpeechService _speechService;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _messageSubscription;
  // Use correct enum name
  core.SpeechServiceState _currentVoiceState = core.SpeechServiceState.idle;
  bool _isFirstInteraction = true; // Track initial interaction

  @override
  void initState() {
    super.initState();

    _speechService = Provider.of<core.SpeechService>(context, listen: false);

    // Ensure fresh state each time screen is built
    _speechService.resetConversation();

    // Listener for voice state changes
    _stateSubscription = _speechService.onStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _currentVoiceState = state; // Use correct enum name
          // Set loading indicator when voice service is processing
          _isLoadingAI = (state == core.SpeechServiceState.processing);
        });
      }
    });

    // Listener for new messages (from voice input or AI response via voice service)
    _messageSubscription = _speechService.onMessageReceived.listen((message) {
      if (mounted) {
        setState(() {
          // Find existing message by ID
          int existingIndex = _messages.indexWhere((m) => m.id == message.id);

          if (existingIndex != -1) {
            // If message exists, update it
            _messages[existingIndex] = message;
          } else {
            // If message is new, add it
            _messages.add(message);
          }
        });
        _scrollToBottom();
      }
    });

    // Retrieve the current request from the provider.
    final requestProvider = Provider.of<RequestProvider>(
      context,
      listen: false,
    );
    final currentRequest = requestProvider.currentRequest;

    // Determine the initial prompt shown to the user (welcome message)
    String initialPrompt;

    // Determine the system prompt to send to ChatGPT (more detailed instructions)
    // This prompt will be used in all subsequent ChatGPT calls
    String category = "";

    // Check if this is a medical question type request
    final RequestType requestType =
        currentRequest?.requestType ??
        (widget.isSynchronous
            ? RequestType.consult
            : RequestType.medicalQuestion);

    // For medical questions, use the specific medical question prompt
    if (requestType == RequestType.medicalQuestion) {
      debugPrint("Using medical question prompt");
      _systemPrompt = medicalQuestionPrompt;
      initialPrompt = providerPromptQuestion;
    } else {
      // Regular consultation flow
      if (widget.category != null) {
        // If category is explicitly provided (via parameter)
        category = widget.category!;
        initialPrompt = getInitialPrompt(
          requestProvider.providerType,
          requestType,
        );
      } else if (requestProvider.selectedCategory != null) {
        // If category is in the request provider
        category = requestProvider.selectedCategory!;
        initialPrompt = getInitialPrompt(
          requestProvider.providerType,
          requestType,
        );
      } else if (currentRequest != null) {
        // If we have a current request but no category yet
        category = currentRequest.category;
        initialPrompt = getInitialPrompt(
          currentRequest.providerType,
          currentRequest.requestType,
        );
      } else {
        // Fallback case
        initialPrompt = defaultPrompt;
        category = "Other"; // Default category
      }

      // Use the specific initial prompt for voice/text choice
      initialPrompt =
          "Hi, I'm your virtual medical assistant. Enter your symptoms below, or click the microphone to have a voice conversation.";

      // Set the system prompt for consultations
      _systemPrompt = getComplaintPrompt(
        requestProvider.providerType,
        category,
      );
    }

    debugPrint("Using category: $category for system prompt");
    debugPrint("System prompt: $_systemPrompt");

    // Configure SpeechService with the system prompt
    _speechService.setSystemPrompt(_systemPrompt);

    // Add the welcome message to the UI
    _messages.add(
      core.Message(
        isUser: false, // Correct parameter
        content: initialPrompt,
        timestamp: DateTime.now(),
      ),
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _handleSend() async {
    String text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    // Mark that first interaction has happened (if text is sent first)
    if (_isFirstInteraction) {
      _isFirstInteraction = false;
    }

    // Let the SpeechService handle adding the message and getting the AI response
    _speechService.addTextMessage(text);
    _scrollToBottom(); // Scroll after adding text (SpeechService listener will add AI response later)
  }

  void _handleDone() async {
    setState(() {
      _isGeneratingSummary = true;
    });

    // Map core.Message back to Map<String, String> for ChatGPTService
    List<Map<String, String>> conversation =
        _messages.map((m) {
          return {
            "role": m.isUser ? "user" : "assistant", // Use isUser
            "content": m.content,
          };
        }).toList();

    // Determine if this is a medical question
    final requestProvider = Provider.of<RequestProvider>(
      context,
      listen: false,
    );
    final isMedicalQuestion =
        widget.isSynchronous != true &&
        (requestProvider.currentRequest?.requestType ==
            RequestType.medicalQuestion);

    // Use different prompts based on request type
    if (isMedicalQuestion) {
      conversation.insert(0, {
        "role": "system",
        "content": medicalQuestionSummaryPrompt,
      });
      debugPrint("Using medical question summary prompt");
    } else {
      conversation.insert(0, {"role": "system", "content": triagePrompt});
      debugPrint("Using standard triage prompt for consultations");
    }

    String summary = "";
    try {
      // Use existing ChatGPTService instance for summary
      summary = await _chatGPTService.getAIResponse(conversation);

      // Get current user ID for debugging
      final userId = FirebaseAuth.instance.currentUser?.uid;
      debugPrint("Current user ID: $userId");

      if (userId == null) {
        throw Exception("User not authenticated");
      }

      // Save the summary and wait for the operation to complete
      if (!mounted) return;

      // Save conversation messages to provider if not already there
      if (requestProvider.conversation == null) {
        debugPrint("Mapping messages for provider before saving summary");
        // Map core.Message back to app_message.Message
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
        await requestProvider.updateConversation(
          appMessages,
        ); // Pass mapped list
      }

      debugPrint("Is this a medical question? $isMedicalQuestion");

      // If this is an appointment check-in, update the existing appointment
      if (widget.appointmentId != null) {
        final firebaseService = FirebaseService();

        // Update the appointment with the AI triage summary
        await firebaseService.updatePatientRequest(widget.appointmentId!, {
          'aiTriageSummary': summary,
          'status': 'triaged',
        });

        debugPrint(
          "Updated appointment with ID: ${widget.appointmentId} with AI triage summary",
        );
      } else {
        // For medical questions, set the status to pending
        final Map<String, dynamic> additionalData =
            isMedicalQuestion ? {'status': 'pending'} : {};

        // Save the conversation with the summary
        final conversationId = await requestProvider
            .updateConversationWithSummary(summary, additionalData);

        if (conversationId == null) {
          throw Exception(
            "Failed to save summary - returned conversation ID is null",
          );
        }

        debugPrint("Summary saved successfully with ID: $conversationId");

        // For medical questions, refresh the questions provider
        if (isMedicalQuestion && mounted) {
          final medicalQuestionsProvider =
              Provider.of<MedicalQuestionsProvider>(context, listen: false);
          medicalQuestionsProvider.refreshQuestions();
        }
      }

      setState(() {
        _isGeneratingSummary = false;
      });

      // Navigate based on the type of request
      if (!mounted) return;

      if (isMedicalQuestion) {
        // For medical questions, show success message and navigate to MainScreen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Your question has been submitted. A provider will respond soon.",
            ),
            duration: Duration(seconds: 3),
          ),
        );

        // Replace the pop navigation with a proper navigation to MainScreen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      } else {
        // For consultations, navigate to the animation screen
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
      debugPrint("Error generating or saving summary: $e");
      setState(() {
        _isGeneratingSummary = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _messageSubscription?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    // Dispose SpeechService if needed (check package docs/implementation)
    // _speechService.dispose();
    super.dispose();
  }

  Widget _buildMessageBubble(core.Message message) {
    // Map core.Message to app_message.Message for the widget
    final appMessage = app_message.Message(
      sender: message.isUser ? 'patient' : 'ai', // Map isUser back to sender
      content: message.content,
      timestamp: message.timestamp,
    );

    // Animate based on the original core.Message sender
    bool shouldAnimate = !message.isUser && _messages.indexOf(message) == 0;

    // Pass the mapped app_message.Message to the bubble widget
    return AnimatedMessageBubble(message: appMessage, animate: shouldAnimate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: ConsistentAppBar(title: 'Virtual Assistant'),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder:
                  (context, index) => _buildMessageBubble(
                    _messages[index],
                  ), // Passes core.Message
            ),
          ),
          if (_isLoadingAI)
            SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                backgroundColor: theme.scaffoldBackgroundColor,
                color: theme.colorScheme.primary,
              ),
            ),
          _buildInputArea(),
          Padding(
            padding: const EdgeInsets.all(16),
            child:
                _isGeneratingSummary
                    ? Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Generating summary...',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    )
                    : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        // Enable button if last message is from AI and contains the token
                        onPressed:
                            (_messages.isNotEmpty &&
                                    !_messages.last.isUser &&
                                    _messages.last.content.contains(
                                      "[TRIAGE_COMPLETE]",
                                    ))
                                ? _handleDone
                                : null,
                        style: theme.elevatedButtonTheme.style?.copyWith(
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(vertical: 16.0),
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
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final theme = Theme.of(context);

    // Determine microphone icon and action based on state
    IconData micIcon;
    Color micColor = theme.colorScheme.primary;
    VoidCallback? micAction;

    switch (_currentVoiceState) {
      case core.SpeechServiceState.listening:
        micIcon = Icons.mic;
        micColor = Colors.red; // Indicate recording
        micAction = () => _speechService.stopListening();
        break;
      case core.SpeechServiceState.processing:
        micIcon = Icons.settings_voice; // Or show a progress indicator
        micColor = theme.disabledColor;
        micAction = null; // Disable while processing
        break;
      case core.SpeechServiceState.speaking:
        micIcon = Icons.stop_circle_outlined;
        micColor = theme.colorScheme.secondary;
        micAction = () => _speechService.stopSpeaking();
        break;
      case core.SpeechServiceState.idle:
        micIcon = Icons.mic_none;
        micColor = theme.colorScheme.primary;
        // Modify mic action for initial interaction
        micAction = () {
          if (_isFirstInteraction) {
            _isFirstInteraction = false;
            _speechService.initiateVoiceFlow(); // Call new method
          } else {
            _speechService.startListening(); // Original action
          }
        };
        break;
    }

    // Check if triage is complete (using the same logic as the Done button)
    final bool isTriageComplete =
        _messages.isNotEmpty &&
        !_messages.last.isUser &&
        _messages.last.content.contains("[TRIAGE_COMPLETE]");

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ), // Adjust padding
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end, // Align items to bottom
        children: [
          // Microphone Button
          IconButton(
            icon: Icon(micIcon, color: micColor),
            onPressed: micAction,
            tooltip:
                _currentVoiceState == core.SpeechServiceState.listening
                    ? 'Stop Listening'
                    : _currentVoiceState == core.SpeechServiceState.speaking
                    ? 'Stop Speaking'
                    : 'Start Listening',
          ),
          // Text Input Field
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type or tap mic...', // Update hint
                hintStyle: TextStyle(color: theme.hintColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor:
                    theme.inputDecorationTheme.fillColor ??
                    theme.cardColor, // Use theme color
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10, // Adjust padding
                ),
                isDense: true, // Make field less tall
              ),
              keyboardType: TextInputType.multiline,
              maxLines: null,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSend(),
              enabled:
                  !isTriageComplete, // Disable TextField when triage is complete
            ),
          ),
          // Send Button
          IconButton(
            icon: Icon(
              Icons.send,
              color:
                  _textController.text.isEmpty || isTriageComplete
                      ? theme.disabledColor
                      : theme.colorScheme.primary,
            ),
            // Enable only if text is not empty AND triage is not complete
            onPressed:
                _textController.text.isNotEmpty && !isTriageComplete
                    ? _handleSend
                    : null,
          ),
        ],
      ),
    );
  }
}
