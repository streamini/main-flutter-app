import "dart:typed_data";

import "package:broadcast_gemini/config.dart";
import "package:http/http.dart" as http;

class GeminiRequestSender {
  static const String _serverPrivateKey = ApplicationConfig.proxyServerKey;
  static const _serverAddress = ApplicationConfig.serverAddress;

  // text to text request
  Future<String> textToText(String prompt) async {
    return http.post(
      Uri.parse("${_serverAddress}process_text/"),
      body: {
        "prompt": prompt,
        "key": _serverPrivateKey,
      },
    ).toString();
  }

  // audio and prompt to text request
  Future<String> audioAndPromptToText(String prompt, Uint8List audioData) async {
    var request = http.MultipartRequest('POST', Uri.parse("${_serverAddress}process_audio/"))
      ..fields['prompt'] = prompt
      ..fields['key'] = _serverPrivateKey
      ..files.add(http.MultipartFile.fromBytes('audio', audioData, filename: 'audio_file'));
    var response = await request.send();
    if (response.statusCode == 200) {
      return await response.stream.bytesToString();
    } else {
      throw Exception('Failed to process audio and prompt');
    }
  }

  Future<String> videoAndPromptToText(String prompt, Uint8List videoData) async {
    var request = http.MultipartRequest('POST', Uri.parse("${_serverAddress}process_video/"))
      ..fields['prompt'] = prompt
      ..fields['key'] = _serverPrivateKey
      ..files.add(http.MultipartFile.fromBytes('video', videoData, filename: 'video_file'));
    var response = await request.send();
    if (response.statusCode == 200) {
      return await response.stream.bytesToString();
    } else {
      throw Exception('Failed to process video and prompt');
    }
  }
}
