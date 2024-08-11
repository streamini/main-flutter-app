import 'package:broadcast_gemini/config.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

Future<String> changeUIWithGemini(String oldHtml, String userNeed) async {
  String apiKey = ApplicationConfig().apiKey;
  final model = GenerativeModel(model: 'gemini-1.5-pro', apiKey: apiKey);

  String prompt = "Edit the web page according to the following prompt: "
      "$userNeed. Provide only the complete new source code for the web page. "
      "Here is the current web page code: $oldHtml";

  final content = [Content.text(prompt)];
  final response = await model.generateContent(content);

  String responseString = response.text.toString();
  if (responseString.startsWith("```html")) {
    responseString = responseString.substring(7, responseString.length);
  }

  if (responseString.endsWith("```")) {
    responseString = responseString.substring(0, responseString.length - 3);
  }

  return responseString;
}
