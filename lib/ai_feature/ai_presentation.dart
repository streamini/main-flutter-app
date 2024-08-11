import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:broadcast_gemini/backend/ObsAdaptorPro.dart';

Future<void> playObsFromJson() async {
  final directory = "/Users/panotpontreemas/Coding/streamini_backend";
  final path = '$directory/results.json';
  final file = File(path);

  try {
    if (await file.exists()) {
      final jsonStr = await file.readAsString();
      final data = json.decode(jsonStr) as List<dynamic>;

      for (var i = 0; i < data.length; i++) {
        final scene = data[i];
        final url = scene['url'];
        final duration =
            (scene['duration'] as num) * 1000; // Convert to milliseconds
        print(url);
        await browserInputs(
            index: i,
            name: 'input$i',
            web: url,
            px: 0, // Replace with actual x position
            py: 0, // Replace with actual y position
            sx: 1.0, // Replace with actual x scale
            sy: 1.0 // Replace with actual y scale
            );
        await Future.delayed(Duration(milliseconds: duration.toInt()));
      }
    } else {
      print("No JSON file found at $path");
    }
  } catch (e) {
    print("An error occurred: $e");
  }
}

Future<void> browserInputs({
  required int index,
  required String name,
  required String web,
  required double px,
  required double py,
  required double sx,
  required double sy,
}) async {
  String check = '''{
    "requestType": "CreateInput",
    "requestData": {
      "sceneName": "Scene",
      "inputName": "$name",
      "inputKind": "browser_source",
      "inputSettings": {
        "url": "$web"
      },
      "sceneItemEnabled": true,
    }
  }''';

  var response = await obsAdaptor.sendJson(check);
  print("response: $response");
  await getObsInfo();
}

Future<void> getObsInfo() async {
  // Implement your getObsInfo logic here
}
