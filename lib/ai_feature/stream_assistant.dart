import 'dart:typed_data';
import 'package:broadcast_gemini/ai_feature/gemini_request_sender.dart';

class StreamAssistant {
  Future<String> analyzeAudioChunk(List<SoundEffectItem> soundEffectList, String userNote, Uint8List audioChunk) async {
    String prompt = """
      Analyze the provided audio chunk and identify suitable moments for the following sound effects: [${soundEffectList.map((e) => e.title).join(", ")}].
      $userNote
      
      Please suggest any moments within the audio chunk where a sound effect could enhance the experience. For each suggestion, 
      include the sound effect title and the exact start time in seconds from the beginning of the chunk. Use the following format for suggestions:
      
      {
        "title": "Sound effect title",
        "start_time": "2.00",
      }
      
      If there are no suitable moments for any sound effects, please respond with an empty object: {}
    """
        .trim();

    return GeminiRequestSender().audioAndPromptToText(prompt, audioChunk);
  }

  Future<String> generateSoundEffectDescription(Uint8List audioChunk) async {
    String prompt = """
      Given a sound effect, provide a concise and clear description focusing solely on its characteristics such as tone, duration,
      and any distinctive features. Avoid any additional commentary or filler text.
    """.trim();

    return GeminiRequestSender().audioAndPromptToText(prompt, audioChunk);
  }
}

class SoundEffectItem {
  String title;
  String description;
  int millisecondsLength;

  SoundEffectItem({required this.title, required this.description, required this.millisecondsLength});

  @override
  String toString() {
    return 'SoundEffectItem{title: $title, description: $description, millisecondsLength: $millisecondsLength}';
  }
}
