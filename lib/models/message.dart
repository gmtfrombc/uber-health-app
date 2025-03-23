// lib/models/message.dart
class Message {
  final String sender; // 'patient', 'ai', or 'provider'
  final String content;
  final DateTime timestamp;

  Message({
    required this.sender,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static Message fromMap(Map<String, dynamic> map) {
    return Message(
      sender: map['sender'] as String,
      content: map['content'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
