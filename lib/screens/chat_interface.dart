// lib/screens/chat_interface.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../providers/request_provider.dart';
import '../services/chatgpt_service.dart';
import '../utils/prompts.dart'; // Contains defaultPrompt, triagePrompt, medicalQuestionPrompt, and categoryPrompts
import '../widgets/animated_consultation_screen.dart';

class ChatInterface extends StatefulWidget {
  final bool isSynchronous; // true for consult, false for medical question
  final bool
  isImmediate; // For consult: Quick = immediate; for medical question, always immediate (or can adjust if needed)
  final String
  urgency; // For consult: "Quick" or "Routine"; for medical question: "Routine"
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
  bool _triageComplete = false;
  bool _isGeneratingSummary = false; // New flag for summary generation
  final ChatGPTService _chatGPTService = ChatGPTService();

  @override
  void initState() {
    super.initState();
    _messages.add(
      Message(
        sender: 'ai',
        content:
            'Hi there! I\'m your virtual health assistant. I’ll help gather some details about what’s going on so your provider has the right information. \n\nLet\'s start with a brief description of your concern (e.g., I\'ve had a bad sore throat for the last week).\n\nThen I\'ll ask a few follow-up questions to understand your situation better.',
        timestamp: DateTime.now(),
      ),
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
    List<Map<String, String>> conversation =
        _messages.map((m) {
          return {
            "role": m.sender == 'patient' ? "user" : "assistant",
            "content": m.content,
          };
        }).toList();
    final requestProvider = Provider.of<RequestProvider>(
      context,
      listen: false,
    );
    String promptToUse;
    if (requestProvider.selectedCategory == "Medical Question") {
      promptToUse = medicalQuestionPrompt;
    } else if (requestProvider.selectedCategory != null &&
        categoryPrompts.containsKey(requestProvider.selectedCategory)) {
      promptToUse = categoryPrompts[requestProvider.selectedCategory]!;
    } else {
      promptToUse = defaultPrompt;
    }
    conversation.insert(0, {"role": "system", "content": promptToUse});
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
    } catch (e) {
      debugPrint("Error generating summary: $e");
      summary = "Error generating summary.";
    }
    Provider.of<RequestProvider>(context, listen: false)
        .updateConversationWithSummary(summary, {});
    setState(() {
      _isGeneratingSummary = false;
    });
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
