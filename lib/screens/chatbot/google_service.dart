import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:campuslink/data/config.dart';

class GeminiService {
  late final String geminiApiKey;
  final String apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=';

  // Constructor that initializes the API key from environment variables
  GeminiService() {
    // Try to get API key from .env file, with a fallback empty string
    try {
      geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (geminiApiKey.isEmpty) {
        debugPrint('WARNING: GEMINI_API_KEY not found in environment variables');
      }
    } catch (e) {
      debugPrint('ERROR: Could not initialize dotenv - $e');
      geminiApiKey = '';
    }
  }

  // This method transforms text into a more structured format
  static String _transformText(String text) {
    return text
        .replaceAllMapped(
            RegExp(r'\*\*(.*?)\*\*'), (match) => '`${match.group(1)!}`')
        .replaceAllMapped(RegExp(r'^\* ', multiLine: true), (match) => '• ')
        .replaceAllMapped(
            RegExp(r'```(.*?)```', dotAll: true),
            (match) => '\n```\n${match.group(1)!.trim()}\n```\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  // AI Response Method with Enhanced Processing
  Future<String> sendMessage(String prompt, String institution) async {
    if (geminiApiKey.isEmpty) {
      return 'Error: Gemini API key not configured. Please check your environment variables.';
    }

    prompt = prompt.toLowerCase().trim();

    try {
      // Fetching answers related to the institution
      final chatbotApiUrl = '${Config.baseUrl}/clink/api/chatbot.php';
      final response =
          await http.get(Uri.parse('$chatbotApiUrl?institution=$institution'));

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        if (responseBody['success'] == true) {
          List<dynamic> answers = responseBody['answers'];
          String formattedAnswers = answers
              .map((answer) =>
                  "Category: ${answer['category']}\nAnswer: ${answer['answer']}")
              .join("\n\n");

          // Generate a prompt for Gemini API based on the fetched answers
          final geminiApiUrl =
              'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey';
          final response = await http.post(
            Uri.parse(geminiApiUrl),
            headers: {"Content-Type": "application/json"},
            body: json.encode({
              "contents": [
                {
                  "parts": [
                    {
                      "text": '''
                        You are Campus Master, an advanced AI assistant specializing in information about the college $institution.
                        Use the following context for the institution's answers and categories:

                        $formattedAnswers

                        Instructions:
                        - Provide answers based on the relevant categories and answers from the provided context, focusing on the  $institution information.
                        - Prioritize responses related to computer science, IT, BCA, and other academic programs, eligibility, faculty, placements, and related technical subjects.
                        - Answer questions specific to the  $institution, including details about its academic offerings, infrastructure, faculty, and placement opportunities.
                        - For any other queries not specifically related to the  $institution but still involving technical subjects like computer science and IT, use the general knowledge from the context while focusing on the  $institution offerings and expertise.
                        - Ensure your response is clear, structured, and relevant to the user's query, emphasizing the  $institution strengths and offerings.

                        User Query: "$prompt"

                        Provide a clear and structured response based on the provided answers, categorie and you can answer other  $institution not related question's answer.'''
                    }
                  ]
                }
              ]
            }),
          );

          if (response.statusCode == 200) {
            final responseBody = json.decode(response.body);
            String responseText =
                responseBody['candidates'][0]['content']['parts'][0]['text'];

            responseText = _transformText(responseText);

            return responseText.isNotEmpty
                ? responseText
                : "I apologize, but I couldn't find specific information about your query.";
          } else {
            return 'Error: Unable to get response from Gemini. Status code: ${response.statusCode}';
          }
        } else {
          return responseBody['message'] ??
              "Unable to fetch data for the institution.";
        }
      } else {
        return 'Error: Unable to fetch data. Status code: ${response.statusCode}';
      }
    } catch (e) {
      return 'An error occurred while processing your request: $e';
    }
  }
}
