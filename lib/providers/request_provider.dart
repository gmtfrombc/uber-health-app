// lib/providers/request_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import '../models/patient_request.dart';
import '../services/firebase_service.dart';

class RequestProvider with ChangeNotifier {
  PatientRequest? currentRequest;
  List<Message>? conversation;
  String? lastConversationId; // Holds the ID of the saved conversation

  final FirebaseService _firebaseService = FirebaseService();

  void createRequest(PatientRequest request) {
    currentRequest = request;
    notifyListeners();
  }

  void clearRequest() {
    currentRequest = null;
    conversation = null;
    lastConversationId = null;
    notifyListeners();
  }

  /// Updates the conversation.
  /// If the last message is from the AI, use its content as the summary.
  Future<void> updateConversation(List<Message> messages) async {
    conversation = messages;
    debugPrint("Updating conversation with ${messages.length} messages");
    notifyListeners();

    String? summary;
    if (conversation != null &&
        conversation!.isNotEmpty &&
        conversation!.last.sender == 'ai') {
      summary = conversation!.last.content;
    }

    // Prepare the data map including the summary (if available).
    final data = {
      'patientId': currentRequest!.patientId,
      'requestType': currentRequest!.requestType.toString(),
      'urgency': currentRequest!.urgency,
      'status': 'pending',
      'messages': conversation!.map((msg) => msg.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (summary != null) 'aiTriageSummary': summary,
    };

    if (lastConversationId == null) {
      // Create a new conversation document.
      lastConversationId = await _firebaseService.savePatientRequest(
        currentRequest!,
        conversation!,
        aiTriageSummary: summary,
      );
      debugPrint("Conversation created with ID: $lastConversationId");
      notifyListeners();
    } else {
      // Update the existing conversation document.
      await _firebaseService.updatePatientRequest(lastConversationId!, data);
      debugPrint("Conversation updated with ID: $lastConversationId");
    }
  }
}
