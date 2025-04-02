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

      // Check if this is likely a medical question (look for the prompt)
      bool isMedicalQuestion = false;
      if (conversation.isNotEmpty && conversation[0]['role'] == 'system') {
        final systemPrompt = conversation[0]['content'] ?? '';
        isMedicalQuestion =
            systemPrompt.contains('clarifying question') &&
            systemPrompt.contains('[TRIAGE_COMPLETE]');
      }

      // Log the conversation type
      debugPrint(
        'Processing ${isMedicalQuestion ? "medical question" : "standard consultation"}',
      );

      // Count user messages to determine where we are in the conversation flow
      int userMessageCount = 0;
      for (var msg in conversation) {
        if (msg['role'] == 'user') {
          userMessageCount++;
        }
      }
      debugPrint('User message count: $userMessageCount');

      // Convert conversation to a format that Firebase Functions can handle
      final List<Map<String, dynamic>> formattedMessages =
          conversation.map((msg) {
            return {'role': msg['role'], 'content': msg['content']};
          }).toList();

      final requestData = {
        'messages': formattedMessages,
        'maxTokens':
            isMedicalQuestion ? 300 : 150, // More tokens for medical questions
        'temperature':
            isMedicalQuestion
                ? 0.5
                : 0.7, // Lower temperature for more consistent medical responses
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
        final response = data['content'] as String;

        // For medical questions, manage the TRIAGE_COMPLETE token appropriately
        if (isMedicalQuestion) {
          // If the response already contains the token, check if it's appropriate timing
          if (response.contains("[TRIAGE_COMPLETE]")) {
            // Only keep the token if this is a follow-up to the patient's answer to the clarifying question
            // or if it's a direct response that doesn't require clarification
            if (userMessageCount < 2) {
              // First question from patient - we expect AI to ask a clarifying question
              // Remove the token if it was added too early
              debugPrint('Removing premature TRIAGE_COMPLETE token');
              return response.replaceAll("[TRIAGE_COMPLETE]", "").trim();
            } else {
              // Second or later message from patient - appropriate to complete triage
              debugPrint('Keeping appropriate TRIAGE_COMPLETE token');
              return response;
            }
          }
          // If we need to add the token (only for second user message onwards)
          else if (userMessageCount >= 2) {
            debugPrint('Adding missing TRIAGE_COMPLETE token after follow-up');
            return "$response [TRIAGE_COMPLETE]";
          }
        }

        return response;
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
