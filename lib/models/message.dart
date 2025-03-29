// lib/models/message.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String sender; // 'patient', 'ai', or 'provider'
  final String text;
  final DateTime timestamp;

  // Constructor that supports both old (content) and new (text) parameter names
  Message({
    required this.sender,
    String? text,
    String? content,
    required this.timestamp,
  }) : text = text ?? content ?? '';

  // Getter for backward compatibility
  String get content => text;

  // Convenience properties to check sender type
  bool get isUserMessage => sender.toLowerCase() == 'patient';
  bool get isAiMessage => sender.toLowerCase() == 'ai';
  bool get isProviderMessage => sender.toLowerCase() == 'provider';

  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'content': text, // Use 'content' in the map to match existing data
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static Message fromMap(Map<String, dynamic> map) {
    // Debug logging to see what fields are available
    if (kDebugMode) {
      debugPrint('Message.fromMap received: ${map.keys.join(', ')}');
      if (map['sender'] == null) debugPrint('⚠️ sender is null');
      if (map['content'] == null) debugPrint('⚠️ content is null');
      if (map['timestamp'] == null) debugPrint('⚠️ timestamp is null');
    }

    // Safely extract values with fallbacks to avoid runtime errors
    final String sender = map['sender'] as String? ?? 'unknown';
    final String content = map['content'] as String? ?? '';

    DateTime timestamp;
    try {
      if (map['timestamp'] != null) {
        if (map['timestamp'] is String) {
          timestamp = DateTime.parse(map['timestamp'] as String);
        } else if (map['timestamp'] is Timestamp) {
          timestamp = (map['timestamp'] as Timestamp).toDate();
        } else {
          debugPrint(
            '⚠️ Unknown timestamp type: ${map['timestamp'].runtimeType}',
          );
          timestamp = DateTime.now();
        }
      } else {
        timestamp = DateTime.now();
      }
    } catch (e) {
      debugPrint('⚠️ Error parsing timestamp: $e');
      timestamp = DateTime.now();
    }

    return Message(sender: sender, content: content, timestamp: timestamp);
  }
}
