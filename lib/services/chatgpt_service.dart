// lib/services/chatgpt_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatGPTService {
  final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  late final FirebaseFunctions _functions;

  ChatGPTService() {
    // Configure Firebase Functions to use the emulator if we're in debug mode
    _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
    if (kDebugMode) {
      _functions.useFunctionsEmulator('localhost', 5002);
      debugPrint('Using Firebase Functions emulator on port 5002');
    }
  }

  /// Decides whether to use Firebase Functions or direct API call based on availability
  Future<String> getAIResponse(List<Map<String, String>> conversation) async {
    try {
      // Try to use Firebase Functions first
      return await _getAIResponseViaFirebase(conversation);
    } catch (e) {
      debugPrint('Firebase function failed, falling back to direct API: $e');
      // Fall back to direct API call if Firebase function fails
      return await _getAIResponseDirect(conversation);
    }
  }

  /// Sends the conversation history to OpenAI via Firebase Cloud Functions
  Future<String> _getAIResponseViaFirebase(
    List<Map<String, String>> conversation,
  ) async {
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

      // Call the Firebase function
      final result = await _functions
          .httpsCallable(
            'generateAIResponse',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
          )
          .call({
            'messages': formattedMessages,
            'maxTokens': 150,
            'temperature': 0.7,
            'apiKey': _apiKey,
          });

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
      rethrow; // Rethrow to trigger fallback
    }
  }

  /// Sends the conversation history directly to the OpenAI API as fallback
  Future<String> _getAIResponseDirect(
    List<Map<String, String>> conversation,
  ) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $_apiKey",
    };

    final body = jsonEncode({
      "model": "gpt-4o",
      "messages": conversation,
      "temperature": 0.7,
      "max_tokens": 150,
    });

    debugPrint('Sending request to OpenAI API directly');
    final response = await http.post(url, headers: headers, body: body);
    debugPrint('OpenAI API response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final aiMessage = data["choices"][0]["message"]["content"];
      return aiMessage;
    } else {
      debugPrint('OpenAI API error: ${response.body}');
      throw Exception(
        "Failed to get AI response: ${response.statusCode} - ${response.body}",
      );
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
        'apiKey': _apiKey,
      });

      // Return the summary text.
      if (result.data['success'] == true) {
        return result.data['summary'] as String;
      } else {
        throw Exception('Failed to generate summary');
      }
    } catch (e) {
      debugPrint('Error generating medical summary: $e');
      // Fall back to direct API if Firebase function fails
      return _generateMedicalSummaryDirect(
        messages: messages,
        patientData: patientData,
        category: category,
        providerType: providerType,
      );
    }
  }

  /// Generate a medical summary using direct API call as fallback
  Future<String> _generateMedicalSummaryDirect({
    required List<Map<String, String>> messages,
    required Map<String, dynamic>? patientData,
    required String category,
    required String providerType,
  }) async {
    try {
      // Create system prompt for OpenAI
      final systemPrompt = '''
You are a medical AI assistant tasked with creating professional medical summaries.
Based on the conversation, extract patient information and format it as a concise medical summary.
Focus on key details related to the patient's symptoms, medical history, and current condition.
Consider the specific category ($category) and provider type ($providerType) when creating this summary.
Your summary will be used by healthcare providers to quickly understand the patient's situation.
''';

      // Prepare the messages with system prompt
      final chatMessages = [
        {"role": "system", "content": systemPrompt},
        ...messages,
      ];

      // Send direct request to OpenAI API
      final url = Uri.parse("https://api.openai.com/v1/chat/completions");
      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_apiKey",
      };

      final body = jsonEncode({
        "model": "gpt-4o",
        "messages": chatMessages,
        "temperature": 0.3,
        "max_tokens": 500,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["choices"][0]["message"]["content"];
      } else {
        throw Exception("Failed to generate summary: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint('Error in direct medical summary generation: $e');
      return 'Summary generation error: An unexpected error occurred while creating your medical summary';
    }
  }
}
