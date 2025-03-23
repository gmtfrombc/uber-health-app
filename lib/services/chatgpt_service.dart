// lib/services/chatgpt_service.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatGPTService {
  late final FirebaseFunctions _functions;

  ChatGPTService() {
    // Configure Firebase Functions to use the production environment
    _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

    // Enable emulator in debug mode for faster development
    if (kDebugMode) {
      _functions.useFunctionsEmulator('localhost', 5003);
      debugPrint('Using Firebase Functions emulator on port 5003');
    }
  }

  /// Gets an AI response using Firebase Functions
  Future<String> getAIResponse(List<Map<String, String>> conversation) async {
    try {
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('User not authenticated');
        return 'Please sign in to use this feature.';
      }

      // Convert conversation to a format that Firebase Functions can handle
      final List<Map<String, dynamic>> formattedMessages =
          conversation.map((msg) {
            return {'role': msg['role'], 'content': msg['content']};
          }).toList();

      final requestData = {
        'messages': formattedMessages,
        'maxTokens': 150,
        'temperature': 0.7,
      };

      debugPrint('Sending request: $requestData');

      // Call the Firebase function
      final result = await _functions
          .httpsCallable(
            'generateAIResponse',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
          )
          .call(requestData);

      // Process the response
      final data = result.data;

      if (data['success'] == true && data['content'] != null) {
        return data['content'] as String;
      } else {
        // Extract error details
        String errorMessage = 'Unknown error';
        if (data['error'] != null) {
          errorMessage = data['error'].toString();
        }
        debugPrint('AI response error: $errorMessage');
        return 'I apologize, but I encountered an issue processing your request: $errorMessage. Please try again.';
      }
    } catch (e) {
      debugPrint('Error getting AI response from Firebase: $e');
      return 'An error occurred while processing your request. Please try again later.';
    }
  }

  /// Generate a medical summary from a conversation.
  Future<String> generateMedicalSummary({
    required List<Map<String, String>> messages,
    required Map<String, dynamic>? patientData,
    required String category,
    required String providerType,
  }) async {
    try {
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('User not authenticated');
        return 'Please sign in to use this feature.';
      }

      // Create a callable instance for the Firebase Function.
      final callable = FirebaseFunctions.instance.httpsCallable(
        'generateMedicalSummary',
      );

      // Call the function with the messages and patient data.
      final result = await callable.call({
        'messages': messages,
        'patientData': patientData,
        'category': category,
        'providerType': providerType,
      });

      // Return the summary text.
      if (result.data['success'] == true) {
        return result.data['summary'] as String;
      } else {
        throw Exception('Failed to generate summary');
      }
    } catch (e) {
      debugPrint('Error generating medical summary: $e');
      return 'An error occurred while generating your medical summary. Please try again later.';
    }
  }
}
