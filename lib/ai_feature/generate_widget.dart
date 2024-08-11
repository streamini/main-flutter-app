import 'package:broadcast_gemini/config.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiGenerateWidget {
  Future<String> generateWidget(String userNeed) async {
    String apiKey = ApplicationConfig().apiKey;
    final model = GenerativeModel(model: 'gemini-1.5-pro', apiKey: apiKey);

    String prompt =
        "Generate HTML code suitable for use as a widget in OBS with a browser widget. "
        "The widget should fulfill the following user requirement: $userNeed. "
        "Provide only the HTML code that is ready to be copied and run.";
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
}
