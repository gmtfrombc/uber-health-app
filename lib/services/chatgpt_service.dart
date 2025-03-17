// lib/services/chatgpt_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatGPTService {
  final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  /// Sends the conversation history to the OpenAI ChatGPT API and returns the AI's response.
  Future<String> getAIResponse(List<Map<String, String>> conversation) async {
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

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final aiMessage = data["choices"][0]["message"]["content"];
      return aiMessage;
    } else {
      throw Exception(
        "Failed to get AI response: ${response.statusCode} - ${response.body}",
      );
    }
  }
}
