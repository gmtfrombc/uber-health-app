import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/patient_request.dart';
import '../services/firebase_service.dart';

class RequestProvider with ChangeNotifier {
  PatientRequest? currentRequest;
  List<Message>? conversation;
  String? lastConversationId;
  String? selectedCategory;
  ProviderType providerType = ProviderType.medicalProvider;

  void setProviderType(ProviderType type) {
    providerType = type;
    notifyListeners();
  }

  void createRequest(PatientRequest request) {
    currentRequest = request;
    notifyListeners();
  }

  void setCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void clearRequest() {
    currentRequest = null;
    conversation = null;
    lastConversationId = null;
    selectedCategory = null;
    providerType = ProviderType.medicalProvider;
    notifyListeners();
  }

  Future<void> updateConversation(List<Message> messages) async {
    conversation = messages;
    notifyListeners();

    if (currentRequest != null && conversation != null) {
      Map<String, dynamic> data = {
        'patientId': currentRequest!.patientId,
        'requestType': currentRequest!.requestType.name,
        'urgency': currentRequest!.urgency,
        'category': currentRequest!.category,
        'providerType': providerType.name,
        'status': 'pending',
        'messages': conversation!.map((msg) => msg.toMap()).toList(),
      };

      if (lastConversationId == null) {
        lastConversationId = await FirebaseService().savePatientRequest(
          currentRequest!,
          conversation!,
        );
        notifyListeners();
      } else {
        await FirebaseService().updatePatientRequest(lastConversationId!, data);
      }
    }
  }

  Future<void> updateConversationWithSummary(
    String summary,
    Map<String, dynamic> additionalData,
  ) async {
    if (currentRequest == null || conversation == null) return;

    Map<String, dynamic> data = {
      'patientId': currentRequest!.patientId,
      'requestType': currentRequest!.requestType.name,
      'urgency': currentRequest!.urgency,
      'category': currentRequest!.category,
      'providerType': providerType.name,
      'status': 'pending',
      'messages': conversation!.map((msg) => msg.toMap()).toList(),
      'aiTriageSummary': summary,
      ...additionalData,
    };

    if (lastConversationId == null) {
      lastConversationId = await FirebaseService().savePatientRequest(
        currentRequest!,
        conversation!,
        aiTriageSummary: summary,
        status: 'pending',
        providerResponse: additionalData['providerResponse'],
        providerInstructions: additionalData['providerInstructions'],
      );
      notifyListeners();
    } else {
      await FirebaseService().updatePatientRequest(lastConversationId!, data);
    }
  }
}
