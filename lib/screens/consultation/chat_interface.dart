// lib/screens/consultation/chat_interface.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/message.dart';
import '../../providers/request_provider.dart';
import '../../models/patient_request.dart';
import '../../services/chatgpt_service.dart';
import '../../utils/prompts.dart';
import '../../widgets/animated_consultation_screen.dart';
import '../../widgets/animated_message_bubble.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import '../../providers/medical_questions_provider.dart';
import '../../theme.dart';
import '../../screens/main_screen.dart';

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
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingAI = false;
  bool _triageComplete = false;
  bool _isGeneratingSummary = false; // New flag for summary generation
  final ChatGPTService _chatGPTService = ChatGPTService();
  String _systemPrompt = ""; // Store the system prompt for consistent use

  @override
  void initState() {
    super.initState();
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

      // Set the system prompt for consultations
      _systemPrompt = getComplaintPrompt(
        requestProvider.providerType,
        category,
      );
    }

    debugPrint("Using category: $category for system prompt");
    debugPrint("System prompt: $_systemPrompt");

    // Add the welcome message to the UI
    _messages.add(
      Message(sender: 'ai', content: initialPrompt, timestamp: DateTime.now()),
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
    if (_triageComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Triage is complete. Please click 'Done' to continue."),
        ),
      );
      return;
    }
    setState(() {
      _messages.add(
        Message(sender: 'patient', content: text, timestamp: DateTime.now()),
      );
      _textController.clear();
      _isLoadingAI = true;
    });
    _scrollToBottom();

    // Create the conversation history for ChatGPT
    List<Map<String, String>> conversation =
        _messages.map((m) {
          return {
            "role": m.sender == 'patient' ? "user" : "assistant",
            "content": m.content,
          };
        }).toList();

    // Use the stored system prompt for all ChatGPT interactions
    conversation.insert(0, {"role": "system", "content": _systemPrompt});

    // Check if we've reached the maximum number of exchanges
    int patientCount = _messages.where((m) => m.sender == 'patient').length;
    debugPrint("Patient message count: $patientCount");

    // Log if we're in a medical question flow
    bool isMedicalQuestion = _systemPrompt.contains('[TRIAGE_COMPLETE]');
    debugPrint("Is medical question: $isMedicalQuestion");
    debugPrint(
      "Current message sequence: ${patientCount == 1 ? 'Initial question' : 'Follow-up response'}",
    );

    if (patientCount >= 10) {
      debugPrint("Maximum message count reached, marking triage as complete");
      setState(() {
        _messages.add(
          Message(
            sender: 'ai',
            content:
                "Okay, I have all the information that I need. Please click 'Done' to continue.",
            timestamp: DateTime.now(),
          ),
        );
        _isLoadingAI = false;
        _triageComplete = true;
      });
      _scrollToBottom();
      return;
    }

    try {
      // Get response from AI
      debugPrint("Sending conversation to ChatGPT");
      final aiResponse = await _chatGPTService.getAIResponse(conversation);
      debugPrint(
        "Received response from ChatGPT: ${aiResponse.substring(0, aiResponse.length > 50 ? 50 : aiResponse.length)}...",
      );

      // Check for the triage complete token
      final bool containsTriageComplete = aiResponse.contains(
        "[TRIAGE_COMPLETE]",
      );
      debugPrint("Contains TRIAGE_COMPLETE token: $containsTriageComplete");

      // For medical questions, the first response (to the initial question) should not have the TRIAGE_COMPLETE token
      // unless it's a simple question that doesn't need clarification
      if (isMedicalQuestion && patientCount == 1 && containsTriageComplete) {
        debugPrint(
          "Medical question first response with TRIAGE_COMPLETE - simple question that doesn't need clarification",
        );
      } else if (isMedicalQuestion &&
          patientCount == 1 &&
          !containsTriageComplete) {
        debugPrint(
          "Medical question first response without TRIAGE_COMPLETE - expecting clarifying question",
        );
      } else if (isMedicalQuestion &&
          patientCount == 2 &&
          containsTriageComplete) {
        debugPrint(
          "Medical question second response with TRIAGE_COMPLETE - completing triage after clarification",
        );
      }

      if (containsTriageComplete) {
        // Remove the token from the displayed message
        final cleanedResponse =
            aiResponse.replaceAll("[TRIAGE_COMPLETE]", "").trim();

        debugPrint("Triage complete token found, marking triage as complete");
        setState(() {
          _messages.add(
            Message(
              sender: 'ai',
              content:
                  cleanedResponse.isEmpty
                      ? "Okay, I have all the information that I need. Please click 'Done' to continue."
                      : cleanedResponse,
              timestamp: DateTime.now(),
            ),
          );
          _isLoadingAI = false;
          _triageComplete = true;
        });
      } else {
        // Regular message, no complete token
        setState(() {
          _messages.add(
            Message(
              sender: 'ai',
              content: aiResponse,
              timestamp: DateTime.now(),
            ),
          );
          _isLoadingAI = false;
        });
      }
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoadingAI = false;
        _messages.add(
          Message(
            sender: 'ai',
            content:
                "Sorry, there was an error processing your message. Please try again.",
            timestamp: DateTime.now(),
          ),
        );
      });
      debugPrint("Error getting AI response: $e");
    }
  }

  void _handleDone() async {
    if (!_triageComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Triage is not complete yet.")),
      );
      return;
    }
    setState(() {
      _isGeneratingSummary = true;
    });
    // Build conversation for summary generation.
    List<Map<String, String>> conversation =
        _messages.map((m) {
          return {
            "role": m.sender == 'patient' ? "user" : "assistant",
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
        debugPrint("Adding messages to provider before saving summary");
        await requestProvider.updateConversation(_messages);
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
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildMessageBubble(Message message) {
    // Only animate the first AI message
    bool shouldAnimate =
        message.sender == 'ai' && _messages.indexOf(message) == 0;

    return AnimatedMessageBubble(message: message, animate: shouldAnimate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Virtual Assistant')),
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder:
                  (context, index) => _buildMessageBubble(_messages[index]),
            ),
          ),
          if (_isLoadingAI)
            SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                backgroundColor: AppTheme.backgroundColor,
                color: AppTheme.primaryColor,
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 4,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Describe your symptoms...',
                      hintStyle: TextStyle(color: AppTheme.textTertiaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSend(),
                    enabled: !_triageComplete,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color:
                        _triageComplete
                            ? AppTheme.textTertiaryColor
                            : AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _triageComplete ? null : _handleSend,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child:
                _isGeneratingSummary
                    ? Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Generating summary...',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    )
                    : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _triageComplete ? _handleDone : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
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
}
