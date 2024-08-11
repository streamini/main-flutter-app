import 'package:google_generative_ai/google_generative_ai.dart';

Future<String> generateScene(String userNeed) async {
  String apiKey = "AIzaSyCtFOrYNBH_VIsjPi7zc3kgBDx5MgVCLtY";

  final model = GenerativeModel(model: 'gemini-1.5-pro', apiKey: apiKey);

  var userNeed = "Create a scene with a monitor_capture and a text hello.";

  var jsonTemplate = """{
    "requestType": "CreateInput",
    "requestData": {
      "sceneName": "Scene",
      "inputName": "test2",
      "inputKind": "browser_source",
      "inputSettings": null,
      "sceneItemEnabled": true, 
      "scene-item-properties": {
        "position": {
            "x": 300,
            "y": 200
        },
        "scale": {
            "x": 1.0,
            "y": 1.0
        }
      }
    }
  }""";

  var inputKind = """image_source",
    "color_source_v3",
    "slideshow",
    "browser_source",
    "ffmpeg_source",
    "text_gdiplus",
    "text_ft2_source",
    "monitor_capture",
    "window_capture",
    "game_capture",
    "dshow_input",
    "wasapi_input_capture",
    "wasapi_output_capture",
    "wasapi_process_output_capture""";

  String prompt =
      "Generate a JSON configuration for creating a scene on WebSocket OBS. "
      "Modify the following JSON template and inputKind to include the user's needs specified below: "
      "User needs: $userNeed. "
      "Template: $jsonTemplate. "
      "InputKind: $inputKind. "
      "if user need more than one source, please provide the JSON code for each source. "
      "Please provide only the JSON code.";

  final content = [Content.text(prompt)];
  final response = await model.generateContent(content);

  return response.text.toString();
}
