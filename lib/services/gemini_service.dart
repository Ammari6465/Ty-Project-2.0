// NOTE: This is a placeholder file for Google Generative AI Service.
// You need to get an API key from https://aistudio.google.com/app/apikey
// It's free to use within generous limits.

import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // Replace with your actual API key from Google AI Studio. 
  // It's free! Get one here: https://aistudio.google.com/app/apikey
  // I've added a placeholder key here.
  static const String apiKey = 'AIzaSyA5C39U9STfaqu_WdL1CeaJtvMC0XPorpA'; 

  late final GenerativeModel? _model;
  late ChatSession? _chat;

  GeminiService() {
    try {
      _model = GenerativeModel(
        model: 'gemini-pro', 
        apiKey: apiKey,
      );
      _chat = _model!.startChat();
    } catch (e) {
      _model = null;
      _chat = null;
    }
  }

  Future<String> getChatResponse(String message) async {
    // Fallback to offline responses if Gemini is not available
    if (_chat == null || _model == null) {
      return _getMockResponse(message);
    }
    
    try {
      final response = await _chat!.sendMessage(Content.text(message));
      return response.text ?? "I'm sorry, I couldn't generate a response.";
    } catch (e) {
      // If API fails, use fallback
      return _getMockResponse(message);
    }
  }

  String _getMockResponse(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Comprehensive disaster safety responses
    if (lowerMessage.contains('flood') || lowerMessage.contains('flooding')) {
      return "🌊 **Flood Safety Tips:**\n\n• Move to higher ground immediately\n• Never walk or drive through flood waters (6 inches can knock you down, 2 feet can sweep a vehicle)\n• Turn off utilities if instructed\n• Listen to emergency broadcasts\n• Have an evacuation kit ready with water, food, and documents";
    } else if (lowerMessage.contains('earthquake') || lowerMessage.contains('quake')) {
      return "🏚️ **Earthquake Safety:**\n\n• DROP, COVER, and HOLD ON\n• Get under a sturdy table or desk\n• Stay away from windows and heavy furniture\n• If outside, move to a clear area away from buildings\n• After shaking stops, check for injuries and damage";
    } else if (lowerMessage.contains('fire') || lowerMessage.contains('wildfire')) {
      return "🔥 **Fire Safety:**\n\n• Evacuate immediately if ordered\n• Close all doors and windows\n• Stay low to avoid smoke\n• Have multiple escape routes\n• Call emergency services (911)\n• Never use elevators during building fires";
    } else if (lowerMessage.contains('cyclone') || lowerMessage.contains('hurricane') || lowerMessage.contains('storm')) {
      return "🌀 **Cyclone/Hurricane Safety:**\n\n• Board up windows\n• Secure outdoor objects\n• Stay indoors away from windows\n• Listen to local authorities\n• Have emergency supplies for 3+ days\n• Evacuate if in evacuation zones";
    } else if (lowerMessage.contains('tornado')) {
      return "🌪️ **Tornado Safety:**\n\n• Go to the lowest floor or basement\n• Get under a sturdy table\n• Stay away from windows\n• Cover yourself with blankets or mattress\n• If outside, lie flat in a ditch\n• Never try to outrun a tornado in a vehicle";
    } else if (lowerMessage.contains('tsunami')) {
      return "🌊 **Tsunami Safety:**\n\n• Move to high ground immediately if you feel an earthquake near the coast\n• Go at least 2 miles inland or 100 feet above sea level\n• Don't wait for official warnings\n• Stay away from the beach\n• Multiple waves may come - stay away for hours";
    } else if (lowerMessage.contains('emergency kit') || lowerMessage.contains('supplies')) {
      return "🎒 **Emergency Kit Essentials:**\n\n• Water (1 gallon per person per day for 3 days)\n• Non-perishable food (3-day supply)\n• Flashlight and batteries\n• First aid kit\n• Medications\n• Important documents (copies)\n• Phone charger/power bank\n• Cash\n• Whistle\n• Multi-tool";
    } else if (lowerMessage.contains('first aid') || lowerMessage.contains('injury')) {
      return "🏥 **Basic First Aid:**\n\n• Call emergency services for serious injuries\n• Stop bleeding: Apply direct pressure\n• For burns: Cool with water, don't break blisters\n• CPR: 30 chest compressions, 2 breaths\n• Choking: Heimlich maneuver\n• Keep victim warm and calm\n• Don't move someone with suspected spinal injury";
    } else {
      return "👋 **I'm your Safety Assistant!**\n\nI can help you with:\n• Floods 🌊\n• Earthquakes 🏚️\n• Fires & Wildfires 🔥\n• Cyclones & Hurricanes 🌀\n• Tornadoes 🌪️\n• Tsunamis\n• Emergency Kits 🎒\n• First Aid 🏥\n\nWhat would you like to know about?";
    }
  }
}
