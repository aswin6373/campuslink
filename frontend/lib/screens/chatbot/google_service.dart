import 'package:campuslink/services/api_client.dart';

/// Campus AI assistant.
///
/// Questions are answered by the backend (`POST /api/chatbot/ask`), which
/// holds the Gemini API key server-side and grounds answers on the
/// institution's curated Q&A. The app never touches the AI directly.
class GeminiService {
  /// Returns the assistant's reply, or a friendly error message.
  Future<String> sendMessage(String prompt, String institution) async {
    prompt = prompt.toLowerCase().trim();

    try {
      final result = await ApiClient.post(
        '/api/chatbot/ask',
        body: {'prompt': prompt},
      );
      final answer = result['answer']?.toString() ?? '';
      return answer.isNotEmpty
          ? answer
          : "I apologize, but I couldn't find specific information about your query.";
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Could not reach the assistant. Check your connection and try again.';
    }
  }
}
