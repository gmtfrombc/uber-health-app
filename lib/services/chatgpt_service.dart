// lib/services/chatgpt_service.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatGPTService {
  late final FirebaseFunctions _functions;

  ChatGPTService() {
    // Configure Firebase Functions to use the production environment
    _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

    // For debugging purposes only
    if (kDebugMode) {
      debugPrint('Using production Firebase Functions');
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
      }

      throw Exception(data['error'] ?? 'Unknown error');
    } catch (e) {
      debugPrint('Error getting AI response: $e');
      return 'Sorry, there was an error communicating with the AI service. Please try again later.';
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
