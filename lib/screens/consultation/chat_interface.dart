// lib/screens/consultation/chat_interface.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/message.dart';
import '../../providers/request_provider.dart';
import '../../models/patient_request.dart';
import '../../services/chatgpt_service.dart';
import '../../utils/prompts.dart';
import '../../widgets/animated_consultation_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';

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

    if (widget.category != null) {
      // If category is explicitly provided (via parameter)
      category = widget.category!;
      initialPrompt = getInitialPrompt(
        requestProvider.providerType,
        currentRequest?.requestType ?? RequestType.consult,
      );
    } else if (requestProvider.selectedCategory != null) {
      // If category is in the request provider
      category = requestProvider.selectedCategory!;
      initialPrompt = getInitialPrompt(
        requestProvider.providerType,
        currentRequest?.requestType ?? RequestType.consult,
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

    // Set the system prompt that will be used for all ChatGPT calls
    _systemPrompt = getComplaintPrompt(requestProvider.providerType, category);

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
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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

    int patientCount = _messages.where((m) => m.sender == 'patient').length;
    if (patientCount >= 10) {
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
      final aiResponse = await _chatGPTService.getAIResponse(conversation);
      setState(() {
        _messages.add(
          Message(sender: 'ai', content: aiResponse, timestamp: DateTime.now()),
        );
        _isLoadingAI = false;
      });
      _scrollToBottom();
      if (aiResponse.contains("[TRIAGE_COMPLETE]")) {
        setState(() {
          _messages.removeLast();
          _messages.add(
            Message(
              sender: 'ai',
              content:
                  "Okay, I have all the information that I need. Please click 'Done' to continue.",
              timestamp: DateTime.now(),
            ),
          );
          _triageComplete = true;
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _isLoadingAI = false;
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
    conversation.insert(0, {"role": "system", "content": triagePrompt});
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
      final requestProvider = Provider.of<RequestProvider>(
        context,
        listen: false,
      );

      // Save conversation messages to provider if not already there
      if (requestProvider.conversation == null) {
        debugPrint("Adding messages to provider before saving summary");
        await requestProvider.updateConversation(_messages);
      }

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
        // Regular flow for non-appointments
        final conversationId = await requestProvider
            .updateConversationWithSummary(summary, {});

        if (conversationId == null) {
          throw Exception(
            "Failed to save summary - returned conversation ID is null",
          );
        }

        debugPrint("Summary saved successfully with ID: $conversationId");
      }

      setState(() {
        _isGeneratingSummary = false;
      });

      // Now navigate after the save is complete
      if (!mounted) return;
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
    bool isPatient = message.sender == 'patient';
    return Align(
      alignment: isPatient ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPatient ? Colors.teal[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message.content),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Virtual Assistant')),
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
          if (_isLoadingAI) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your medical info here...',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSend(),
                    enabled: !_triageComplete,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _triageComplete ? null : _handleSend,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child:
                _isGeneratingSummary
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: _triageComplete ? _handleDone : null,
                      child: const Text('Done'),
                    ),
          ),
        ],
      ),
    );
  }
}
