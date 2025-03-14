// lib/screens/chat_interface.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../providers/request_provider.dart';
import '../services/chatgpt_service.dart';
import '../utils/prompts.dart';
import '../widgets/animated_consultation_screen.dart';

class ChatInterface extends StatefulWidget {
  final bool
  isSynchronous; // true for consult (telehealth), false for medical question (messaging)
  final bool isImmediate; // true if "Quick", false if Routine or No Rush
  final String urgency; // "Quick", "Routine", or "No Rush"

  const ChatInterface({
    required this.isSynchronous,
    required this.isImmediate,
    required this.urgency,
    super.key,
  });

  @override
  _ChatInterfaceState createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface> {
  final TextEditingController _textController = TextEditingController();
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingAI = false;
  bool _triageComplete = false; // Flag to indicate triage completion
  final ChatGPTService _chatGPTService = ChatGPTService();

  @override
  void initState() {
    super.initState();
    // Add initial welcome message from the AI triage nurse.
    _messages.add(
      Message(
        sender: 'ai',
        content: 'Hi there, how can I help you today?',
        timestamp: DateTime.now(),
      ),
    );
    _scrollToBottom();
  }

  /// Automatically scrolls the conversation to the bottom.
  void _scrollToBottom() {
    // Delay to ensure the new message is rendered.
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

  /// Handles sending a patient's message and then obtaining the AI response.
  void _handleSend() async {
    String text = _textController.text.trim();
    if (text.isEmpty) return;

    // Prevent further input if triage is already complete.
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

    // Build conversation history for the API call.
    List<Map<String, String>> conversation =
        _messages.map((m) {
          return {
            "role": m.sender == 'patient' ? "user" : "assistant",
            "content": m.content,
          };
        }).toList();
    // Prepend the system prompt (used for ongoing triage).
    conversation.insert(0, {"role": "system", "content": defaultPrompt});

    // Check if enough patient messages have been sent.
    int patientCount = _messages.where((m) => m.sender == 'patient').length;
    if (patientCount >= 10) {
      setState(() {
        _messages.add(
          Message(
            sender: 'ai',
            content: "Okay, I have all the information that I need. Please click 'Done' to continue.",
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
      // Check if the AI indicates triage completion.
      if (aiResponse.contains("[TRIAGE_COMPLETE]")) {
        setState(() {
          // Optionally remove the token from the response.
          _messages.removeLast();
          _messages.add(
            Message(
              sender: 'ai',
              content: "Triage complete. Please click 'Done' to continue.",
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

  /// When 'Done' is tapped, save the conversation and navigate to the animated workflow.
  void _handleDone() {
    if (!_triageComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Triage is not complete yet.")),
      );
      return;
    }
    // Save the conversation via RequestProvider.
    Provider.of<RequestProvider>(
      context,
      listen: false,
    ).updateConversation(_messages);
    // Navigate to the animated consultation screen.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AnimatedConsultationScreen(
              isSynchronous: widget.isSynchronous,
              isImmediate: widget.isImmediate,
              urgency: widget.urgency,
            ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Displays a chat bubble for a given message.
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
      appBar: AppBar(title: const Text('Chat with Triage Nurse')),
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
                      hintText: 'Enter your message...',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSend(),
                    enabled:
                        !_triageComplete, // Disable input if triage is complete.
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
            child: ElevatedButton(
              onPressed: _triageComplete ? _handleDone : null,
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
