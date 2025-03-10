// lib/providers/request_provider.dart
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/patient_request.dart';
import '../services/firebase_service.dart';

class RequestProvider with ChangeNotifier {
  PatientRequest? currentRequest;
  List<Message>? conversation;
  String?
  lastConversationId; // NEW: holds the ID of the last saved conversation

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

  // Update conversation and save to Firestore; capture the document ID.
  Future<void> updateConversation(List<Message> messages) async {
    conversation = messages;
    debugPrint("Updating conversation with ${messages.length} messages");
    notifyListeners();
    if (currentRequest != null && conversation != null) {
      try {
        String docId = await _firebaseService.savePatientRequest(
          currentRequest!,
          conversation!,
        );
        lastConversationId = docId;
        debugPrint("Conversation saved successfully with doc id: $docId");
        notifyListeners();
      } catch (error) {
        debugPrint("Error saving conversation: $error");
      }
    } else {
      debugPrint("No current request or conversation is null");
    }
  }
}
