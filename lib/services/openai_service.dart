import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  // NOTE: storing API keys in source code is not secure for production apps.
  // Ideally use a backend proxy or environment variables.
  static const String apiKey = 'sk-6f3e4a99de1a49d5ab9e4667295a493a'; // DeepSeek API Key
  static const String apiUrl = 'https://api.deepseek.com/chat/completions';

  Future<String> getChatResponse(List<Map<String, String>> messages) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat', 
          'messages': messages,
          'stream': false
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else if (response.statusCode == 429) {
        // Fallback to mock response if quota exceeded
        return _getMockResponse(messages);
      } else {
        throw Exception('Failed to load response: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback for demo purposes
      return _getMockResponse(messages);
    }
  }

  String _getMockResponse(List<Map<String, String>> messages) {
    final lastMessage = messages.last['content']?.toLowerCase() ?? '';
    
    // Simple rule-based responses for demo
    if (lastMessage.contains('flood')) {
      return "[Demo Mode] 🌊 Flood Safety: Move to higher ground immediately. Do not walk or drive through flood waters. Turn off utilities if instructed.";
    } else if (lastMessage.contains('earthquake')) {
      return "[Demo Mode] 🏚️ Earthquake Safety: Drop, Cover, and Hold On. Stay away from windows and heavy furniture. If outside, find a clear spot away from buildings.";
    } else if (lastMessage.contains('fire') || lastMessage.contains('wildfire')) {
      return "[Demo Mode] 🔥 Fire Safety: Evacuate immediately if ordered. Stay low to the ground to avoid smoke. Have an emergency kit ready.";
    } else if (lastMessage.contains('cyclone') || lastMessage.contains('hurricane')) {
      return "[Demo Mode] 🌀 Cyclone Safety: Board up windows. Secure outdoor objects. Stay indoors away from windows. Listen to local authorities.";
    } else {
      return "[Demo Mode] I can help with disaster safety advice. Try asking about floods, earthquakes, fires, or cyclones. (Note: Real AI inactive due to API quota)";
    }
  }
}
