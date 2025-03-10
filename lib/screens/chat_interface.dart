// lib/screens/chat_interface.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/animated_consultation_screen.dart';
import '../providers/request_provider.dart';
import '../models/message.dart'; // Import the Message model

class ChatInterface extends StatefulWidget {
  final bool
  isSynchronous; // true for consult (telehealth), false for medical question (messaging)
  final bool isImmediate; // true if "Quick", false if Routine or No Rush
  final String urgency; // "Quick", "Routine", or "No Rush"

  const ChatInterface({
    required this.isSynchronous,
    required this.isImmediate,
    required this.urgency,
    Key? key,
  }) : super(key: key);

  @override
  _ChatInterfaceState createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface> {
  final TextEditingController _textController = TextEditingController();
  final List<Message> _messages = [];

  // Handle sending a message.
  void _handleSend() {
    String text = _textController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add(
          Message(sender: 'patient', content: text, timestamp: DateTime.now()),
        );
      });
      _textController.clear();
      // Future enhancement: trigger an AI response here.
    }
  }

  // When the user is done, save the conversation and navigate.
  void _handleDone() {
    // Save the conversation in the provider for future use.
    Provider.of<RequestProvider>(
      context,
      listen: false,
    ).updateConversation(_messages);

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
    super.dispose();
  }

  // Widget to display a chat bubble.
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
          // Chat messages area.
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          // Text input area with a send button.
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
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _handleSend,
                ),
              ],
            ),
          ),
          // "Done" button to finalize the conversation.
          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: _handleDone,
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
