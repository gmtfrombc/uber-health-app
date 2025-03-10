// lib/providers/request_provider.dart
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/patient_request.dart';
import '../services/firebase_service.dart'; // Import the Firebase service

class RequestProvider with ChangeNotifier {
  PatientRequest? currentRequest;
  List<Message>? conversation;

  // Create an instance of FirebaseService
  final FirebaseService _firebaseService = FirebaseService();

  void createRequest(PatientRequest request) {
    currentRequest = request;
    notifyListeners();
  }

  void clearRequest() {
    currentRequest = null;
    conversation = null;
    notifyListeners();
  }

  // Update the conversation and save it to Firestore
  void updateConversation(List<Message> messages) {
    conversation = messages;
    debugPrint("Updating conversation with ${messages.length} messages");
    notifyListeners();
    // Save the conversation to Firestore if available.
    if (currentRequest != null && conversation != null) {
      _firebaseService
          .savePatientRequest(currentRequest!, conversation!)
          .then((_) => debugPrint("Conversation saved successfully"))
          .catchError(
            (error) => debugPrint("Error saving conversation: $error"),
          );
    } else {
      debugPrint("No current request or conversation is null");
    }
  }
}
