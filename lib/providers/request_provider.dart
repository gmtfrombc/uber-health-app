import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/patient_request.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestProvider with ChangeNotifier {
  PatientRequest? currentRequest;
  List<Message>? conversation;
  String? lastConversationId;
  String? selectedCategory;
  DateTime? scheduledDateTime;
  ProviderType providerType = ProviderType.medicalProvider;

  void setScheduledDateTime(DateTime dateTime) {
    scheduledDateTime = dateTime;
    notifyListeners();
  }

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

  Future<String?> updateConversationWithSummary(
    String summary,
    Map<String, dynamic> additionalData,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('Attempting to save summary for user: $userId');

    // Initialize currentRequest if it's null
    if (currentRequest == null && userId != null) {
      debugPrint('Creating new request since currentRequest is null');
      currentRequest = PatientRequest(
        patientId: userId,
        requestType: RequestType.medicalQuestion, // Default type
        urgency: 'Routine',
        category: selectedCategory ?? 'General',
        timestamp: DateTime.now(),
      );
    }

    // Initialize conversation if it's null
    if (conversation == null) {
      debugPrint('Creating empty conversation array since it is null');
      conversation = [];
    }

    if (currentRequest == null) {
      debugPrint(
        'ERROR: Cannot save summary: Still no currentRequest - user not logged in?',
      );
      return null;
    }

    debugPrint(
      'Preparing to save summary for user ID: ${currentRequest!.patientId}',
    );

    // Safely use currentRequest after null assertion
    final request = currentRequest!;

    Map<String, dynamic> data = {
      'patientId': request.patientId,
      'requestType': request.requestType.name,
      'urgency': request.urgency,
      'category': request.category,
      'providerType': providerType.name,
      'status': 'pending',
      'messages': conversation!.map((msg) => msg.toMap()).toList(),
      'aiTriageSummary': summary,
      'createdAt': FieldValue.serverTimestamp(),
      ...additionalData,
    };

    debugPrint('Data prepared with summary length: ${summary.length}');

    try {
      if (lastConversationId == null) {
        debugPrint('Creating new conversation document');
        lastConversationId = await FirebaseService().savePatientRequest(
          request,
          conversation!,
          aiTriageSummary: summary,
          status: 'pending',
          providerResponse: additionalData['providerResponse'],
          providerInstructions: additionalData['providerInstructions'],
        );

        if (lastConversationId == null || lastConversationId!.isEmpty) {
          debugPrint(
            'ERROR: Failed to save conversation - returned ID is null or empty',
          );
          return null;
        }

        debugPrint('Created conversation with ID: $lastConversationId');
        notifyListeners();
        return lastConversationId;
      } else {
        debugPrint('Updating existing conversation: $lastConversationId');
        await FirebaseService().updatePatientRequest(lastConversationId!, data);
        debugPrint('Updated conversation successfully');
        return lastConversationId;
      }
    } catch (e) {
      debugPrint('ERROR: Exception saving conversation: $e');
      return null;
    }
  }
}
