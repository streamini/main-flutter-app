import 'package:broadcast_gemini/models/audio_output_status.dart';
import 'package:broadcast_gemini/config.dart';
import 'package:broadcast_gemini/webview/flexible_ui.dart';
import 'package:flutter/material.dart';
import 'package:obs_websocket/obs_websocket.dart';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

GlobalKey<FlexibleUIState>? flexibleUiKey;

class ObsAdaptor {
  ObsWebSocket? obsWebSocket;

  final List<Function()> _onConnectCallbacks = [];

  ObsAdaptor() {
    connectToObs().then((status) {
      if (status != null) {
        print("set value to obsWebSocket");
        obsWebSocket = status;
      } else {
        print("obsWebSocket is null: $status");
      }

      for (var callback in _onConnectCallbacks) {
        callback();
      }
      // empty the list
      _onConnectCallbacks.clear();
    });
  }

  void getOnConnectCallbacks(Function() callback) {
    if (obsWebSocket != null) {
      callback();
    } else {
      _onConnectCallbacks.add(callback);
    }
  }

  Future<ObsWebSocket?> connectToObs() async {
    if (obsWebSocket != null) {
      return obsWebSocket;
    }
    try {
      final obsWebSocket = await ObsWebSocket.connect(
          'ws://${ApplicationConfig.obsIp}:${ApplicationConfig.port}');
      print("Connected to OBS WebSocket: $obsWebSocket");
      return obsWebSocket;
    } catch (e) {
      print("Connect to OBS failed: $e");
      // try again in 0.5 second
      await Future.delayed(const Duration(milliseconds: 500));
      return connectToObs();
    }
  }

  Future<RequestResponse?> sendJson(String jsonString) async {
    if (obsWebSocket == null) {
      print('OBS WebSocket is not connected.');
      return null;
    }

    // Parse JSON
    var parsedJson = json.decode(jsonString);

    // Extract request type and data
    String requestType = parsedJson['requestType'];
    Map<String, dynamic> requestData = parsedJson['requestData'];

    // Create the Dart Request object
    var myrequest = Request(
      requestType, // Change the request type as needed
      requestData: requestData,
    );

    try {
      var response = await obsWebSocket!.sendRequest(myrequest);
      print('Response from OBS: ${response}');
      print('Scene added successfully.');
      //  await getobsinfo();
      return response; // Return the response data
    } catch (e) {
      print('Failed to add scene: $e');
      return null; // Return null in case of an error
    }
  }
}

Future<void> getobsinfo() async {
  var json5 = await getscenelist();
  flexibleUiKey!.currentState!.sendSceneToWebView(json5);
  var crScene = await getCurrentScene();

  var json6 = await getsourceslist(crScene);
  flexibleUiKey!.currentState!.sendSourcesToWebView(json6);

// displaySceneItems(json6);
}

ObsAdaptor obsAdaptor = ObsAdaptor();

Future<void> handleStartRecording() async {
  String check = """{
    "requestType": "GetRecordStatus",
    "requestData": {}
  }""";
  var response = await obsAdaptor.sendJson(check);
  var responseData = response!.toJson(); // This returns a Map
  var outputActive = responseData['responseData']['outputActive'];
  String request;
  if (outputActive == false) {
    request = """{
      "requestType": "StartRecord",
      "requestData": {}
    }""";
  } else {
    request = """{
      "requestType": "StopRecord",
      "requestData": {}
    }""";
  }
  obsAdaptor.sendJson(request); // Send the request
}

Future<void> handleStartStreaming() async {
  String check = """{
    "requestType": "GetStreamStatus",
    "requestData": {}
  }""";
  var response = await obsAdaptor.sendJson(check);
  var responseData = await response!.toJson(); // This returns a Map
  var streaming = await responseData['responseData']['outputActive'];
  String request;
  if (streaming == false) {
    request = """{
  "requestType": "StartStream",
  "requestData": {}
}""";
  } else {
    request = """{
  "requestType": "StopStream",
  "requestData": {}
}""";
  }
  obsAdaptor.sendJson(request); // Send the request
}

Future<void> handleAddScene(String sceneName) async {
  String request = """{
    "requestType": "CreateScene",
    "requestData": {
      "sceneName": "$sceneName"
    }
  }""";
  var response = await obsAdaptor.sendJson(request);
  print("response: $response");
}

Future<void> handleRemoveScene(String sceneName) async {
  String request = """{
    "requestType": "RemoveScene",
    "requestData": {
      "sceneName": "$sceneName"
    }
  }""";
  var response = await obsAdaptor.sendJson(request);
  print("response: $response");
  getobsinfo();
}

Future<void> removeSource(String sceneName) async {
  String request = """{
  "requestType": "RemoveInput",
  "requestData": {
    "inputName": "$sceneName"
  }
}""";
  var response = await obsAdaptor.sendJson(request);
  print("response: $response");
  getobsinfo();
}

Future<String> getscenelist() async {
  String check = """{
    "requestType": "GetSceneList",
    "requestData": {}
  }""";
  var response = await obsAdaptor.sendJson(check);
  var responseData = response!.toJson(); // This returns a Map
  var list = await responseData['responseData'];
  var json = list.toString();
  print("list: $json");
  return json;
}

Future<String> getsourceslist(String currentScene) async {
  String check = """{
  "requestType": "GetSceneItemList",
  "requestData": {
    "sceneName": "$currentScene"
  }
}""";
  var response = await obsAdaptor.sendJson(check);
  var responseData = await response!.toJson(); // This returns a Map
  var list = await responseData['responseData'];
  var json = list.toString();
  print("list: $json");
  return json;
}

Future<String> getCurrentScene() async {
  String check = """{
  "requestType": "GetCurrentProgramScene",
  "requestData": {
    "": ""
  }
}""";
  var response = await obsAdaptor.sendJson(check);
  var responseData = await response!.toJson(); // This returns a Map

  var list = await responseData['responseData'];
  var sceneName = list['currentProgramSceneName'];

  print("sceneName: $sceneName");

  return sceneName;
}

Future<void> createInput(
    String sceneName,
    String inputName,
    String inputKind,
    Map<String, dynamic> inputSettings,
    bool sceneItemEnabled,
    Map<String, dynamic> sceneItemProperties) async {
  String check = """{
    "requestType": "CreateInput",
    "requestData": {
      "sceneName": "$sceneName",
      "inputName": "$inputName",
      "inputKind": "$inputKind",
      "inputSettings": ${jsonEncode(inputSettings)},
      "sceneItemEnabled": $sceneItemEnabled,
      "scene-item-properties": ${jsonEncode(sceneItemProperties)}
    }
  }""";
  var response = await obsAdaptor.sendJson(check);
  var responseData = response!.toJson();
  var data = responseData['responseData'];
  print("Create Input Response: $data");
}

Future<RequestResponse?> addAudioInputToOBS({
  required String scene,
  required String name,
  required String deviceId,
}) {
  String request = """{
    "requestType": "CreateInput",
    "requestData": {
                  "sceneName": "$scene",
                  "inputName": "$name",
                  "inputKind": "coreaudio_input_capture",
                  "inputSettings": {
                      "device_id": "$deviceId"
                  }
              }
  }""";
  return obsAdaptor.sendJson(request).then((value) {
    print("Audio Input Added with response: $value");
    getobsinfo();
    return value;
  });
}


Future<void> browserInput({
  required String scene,
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
      "sceneName": "$scene",
      "inputName": "$name",
      "inputKind": "browser_source",
      "inputSettings": {
        "url": "$web"
      },
      "sceneItemEnabled": true,
      "scene-item-properties": {
        "position": {
          "x": $px,
          "y": $py
        },
        "scale": {
          "x": $sx,
          "y": $sy
        }
      }
    }
  }''';

  var response = await obsAdaptor.sendJson(check);
  print("response: $response");
  await getobsinfo();
}

Future<void> colorSourceInput({
  required String scene,
  required String name,
  required int color,
  required double px,
  required double py,
  required double sx,
  required double sy,
}) async {
  String check = '''{
    "requestType": "CreateInput",
    "requestData": {
      "sceneName": "$scene",
      "inputName": "$name",
      "inputKind": "color_source_v3",
      "inputSettings": {
        "color": $color
      },
      "sceneItemEnabled": true,
      "scene-item-properties": {
        "position": {
          "x": $px,
          "y": $py
        },
        "scale": {
          "x": $sx,
          "y": $sy
        }
      }
    }
  }''';

  var response = await obsAdaptor.sendJson(check);
  print("response: $response");
  await getobsinfo();
}

Future<void> displayCaptureInput({
  required String scene,
  required String name,
  required int
      displayIndex, // This is the display index to capture (0 for the primary display, 1 for the secondary, etc.)
  required double px,
  required double py,
  required double sx,
  required double sy,
}) async {
  String check = '''{
    "requestType": "CreateInput",
    "requestData": {
      "sceneName": "$scene",
      "inputName": "$name",
      "inputKind": "screen_capture",
      "inputSettings": {
        "display": $displayIndex
      },
      "sceneItemEnabled": true,
      "scene-item-properties": {
        "position": {
          "x": $px,
          "y": $py
        },
        "scale": {
          "x": $sx,
          "y": $sy
        }
      }
    }
  }''';

  var response = await obsAdaptor.sendJson(check);
  print("display: $response");
  await getobsinfo();
}

Future<void> imageSourceInput({
  required String scene,
  required String name,
  required String filePath,
  required double px,
  required double py,
  required double sx,
  required double sy,
}) async {
  String check = '''{
    "requestType": "CreateInput",
    "requestData": {
      "sceneName": "$scene",
      "inputName": "$name",
      "inputKind": "image_source",
      "inputSettings": {
        "file": "$filePath"
      },
      "sceneItemEnabled": true,
      "scene-item-properties": {
        "position": {
          "x": $px,
          "y": $py
        },
        "scale": {
          "x": $sx,
          "y": $sy
        }
      }
    }
  }''';

  var response = await obsAdaptor.sendJson(check);
  print("response: $response");
  await getobsinfo();
}

Future<void> textinput({
  required String scene,
  required String name,
  required String text,
  required String face,
  required double size,
  required String style,
  required int color,
  required double px,
  required double py,
  required double sx,
  required double sy,
}) async {
  String request = '''
{
  "requestType": "CreateInput",
  "requestData": {
    "sceneName": "$scene",
    "inputName": "$name",
    "inputKind": "text_ft2_source_v2",
    "inputSettings": {
      "color1": $color,
      "color2": $color,
      "text": "$text",
      "font": {
        "face": "$face",
        "size": $size,
        "style": "$style",
        "color": "$color"
      }
    },
    "sceneItemEnabled": true,
    "scene-item-properties": {
      "position": {
        "x": $px,
        "y": $py
      },
      "scale": {
        "x": $sx,
        "y": $sy
      }
    }
  }
}
''';

  var response = await obsAdaptor.sendJson(request);
  print("response: $response");
  await getobsinfo();
}

Future<void> addVideoCaptureDeviceInput({
  required String scene,
  required String name,
  required String deviceid, // This is the name of the video capture device
  required double px,
  required double py,
  required double sx,
  required double sy,
  required String inputKind, // Add inputKind as a parameter
  required String devicename,
}) async {
  String createInputRequest = '''{
  "requestType": "CreateInput",
  "requestData": {
    "sceneName": "$scene",
    "inputName": "$name",
    "inputKind": "$inputKind",
    "inputSettings": {
      "device": "$deviceid",
      "device_name": "$devicename"
    }
  }
}''';

  var createResponse = await obsAdaptor.sendJson(createInputRequest);
  print(createResponse);
  await getobsinfo();
}

Future<void> windowCaptureInput({
  required String scene,
  required String name,
  required String windowName, // The name of the window to capture
  required double px,
  required double py,
  required double sx,
  required double sy,
}) async {
  String request = '''
{
  "requestType": "CreateInput",
  "requestData": {
    "sceneName": "$scene",
    "inputName": "$name",
    "inputKind": "window_capture",
    "inputSettings": {
      "owner_name": "$windowName",
      "window_name": "$windowName"
    },
    "sceneItemEnabled": true,
    "scene-item-properties": {
      "position": {
        "x": $px,
        "y": $py
      },
      "scale": {
        "x": $sx,
        "y": $sy
      }
    }
  }
}
''';

  var response = await obsAdaptor.sendJson(request);
  print("response: $response");
  await getobsinfo();
}

Future<void> getAudio(String sourceName) async {
  String request = jsonEncode({
    'requestType': 'GetInputVolume',
    'requestData': {'inputName': sourceName},
  });

  try {
    var response = await obsAdaptor.sendJson(request);
    print('Audio settings for $sourceName: ${response}');
  } catch (e) {
    print('Failed to get audio settings: $e');
  }
}

Future<void> setAudio(String sourceName, double volume) async {
  var request = {
    'requestType': 'SetInputVolume',
    'requestData': {
      'inputName': sourceName,
      'inputVolumeMul': volume,
    },
  };

  try {
    var response = await obsAdaptor.sendJson(jsonEncode(request));
    print('Set audio settings for $sourceName: ${response}');
  } catch (e) {
    print('Failed to set audio settings: $e');
  }
}

Future<void> getaudiolist() async {
  var request = {
    "requestType": "GetInputList",
    "requestData": {"inputKind": "coreaudio_input_capture"}
  };

  var response = await obsAdaptor.sendJson(jsonEncode(request));
  print(response);
}

Future<void> getmicvolume() async {
  var request = {
    "requestType": "GetInputVolume",
    "requestData": {"inputName": "Mic/Aux"}
  };

  var response = await obsAdaptor.sendJson(jsonEncode(request));
  print(response);
}

void setCurrentProgramScene(String sceneName) async {
  String request = """{
    "requestType": "SetCurrentProgramScene",
    "requestData": {
      "sceneName": "$sceneName"
    }
  }""";
  var response = await obsAdaptor.sendJson(request);
  print("response: $response");
  await getobsinfo();
}

void updateinputOBS(String sceneName, double scaleX, double scaleY,
    double positionX, double positionY, int sceneItemId) async {
  String request = """{
    "requestType": "SetSceneItemTransform",
    "requestData": {
      "sceneName": "$sceneName",
      "sceneItemId": $sceneItemId,
      "sceneItemTransform": {
        "positionX": $positionX,
        "positionY": $positionY,
        "scaleX": $scaleX,
        "scaleY": $scaleY,
        "visible": true
      }
    }
  }""";
  obsAdaptor.sendJson(request);
}

Future<void> startvirtualcamera() async {
  String request = """{
  "requestType": "StartVirtualCam",
  "requestData": {}
}""";
  await obsAdaptor.sendJson(request);
}

Future<RequestResponse?> shutdownObs() {
  String request = """{
  "requestType": "ShutdownOBS",
  "requestData": {}
}""";
  return obsAdaptor.sendJson(request);
}

Future<RequestResponse?> addSourceFilter(
  String? sourceName,
  String? sourceUUID,
  FilterProperties filterProperties,
) {
  if (sourceName == null && sourceUUID == null) {
    throw Exception('Either sourceName or sourceUUID must be provided');
  }

  Map<String, dynamic> requestData = {};
  if (sourceUUID != null) {
    requestData['sourceUuid'] = sourceUUID;
  } else {
    requestData['sourceName'] = sourceName;
  }

  // add filterName
  requestData['filterName'] = filterProperties.filterName;

  // add filterKind
  requestData['filterKind'] = filterProperties.filterType.value;

  // add filterSettings
  requestData['filterSettings'] = filterProperties.filterSettings.toMap();

  String request = jsonEncode({
    'requestType': 'AddFilterToSource',
    'requestData': requestData,
  });
  return obsAdaptor.sendJson(request);
}

Future<RequestResponse?> getSourceFilterList(
    String? sourceName, String? sourceUuid) async {
  if (sourceName == null && sourceUuid == null) {
    throw Exception('Either sourceName or sourceUuid must be provided');
  }

  Map<String, dynamic> requestData = {};
  if (sourceUuid != null) {
    requestData['sourceUuid'] = sourceUuid;
  } else {
    requestData['sourceName'] = sourceName;
  }

  String request = jsonEncode({
    'requestType': 'GetSourceFilterList',
    'requestData': requestData,
  });

  var response = await obsAdaptor.sendJson(request);
  print('Source filter list: ${response}');
  return response;
}

Future<RequestResponse?> removeSourceFilter(
    String? sourceName, String? sourceUuid, String filterName) async {
  if (sourceName == null && sourceUuid == null) {
    throw Exception('Either sourceName or sourceUuid must be provided');
  }

  Map<String, dynamic> requestData = {};
  if (sourceUuid != null) {
    requestData['sourceUuid'] = sourceUuid;
  } else {
    requestData['sourceName'] = sourceName;
  }

  requestData['filterName'] = filterName;

  String request = jsonEncode({
    'requestType': 'RemoveSourceFilter',
    'requestData': requestData,
  });

  var response = await obsAdaptor.sendJson(request);
  print('Filter removed: ${response}');
  return response;
}

class FilterProperties {
  String filterName;
  SourceFilterKind filterType;
  FilterSetting filterSettings;

  FilterProperties(this.filterName, this.filterType, this.filterSettings);
}

abstract class FilterSetting {
  Map<String, dynamic> toMap();
}

class GpuDelayFilterSetting extends FilterSetting {
  Duration delay;

  GpuDelayFilterSetting(this.delay) {
    if (delay.inMilliseconds < 0) {
      delay = const Duration(milliseconds: 0);
    } else if (delay.inMilliseconds > 500) {
      throw Exception('Delay must be less than 500 milliseconds');
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'delay_ms': delay.inMilliseconds,
    };
  }
}

class OtherFilterSetting extends FilterSetting {
  Map<String, dynamic> settings;

  OtherFilterSetting(this.settings);

  @override
  Map<String, dynamic> toMap() {
    return settings;
  }
}

enum SourceFilterKind {
  maskFilter("mask_filter"),
  maskFilterV2("mask_filter_v2"),
  cropFilter("crop_filter"),
  gainFilter("gain_filter"),
  basicEqFilter("basic_eq_filter"),
  hdrTonemapFilter("hdr_tonemap_filter"),
  colorFilter("color_filter"),
  colorFilterV2("color_filter_v2"),
  scaleFilter("scale_filter"),
  scrollFilter("scroll_filter"),
  gpuDelay("gpu_delay"),
  colorKeyFilter("color_key_filter"),
  colorKeyFilterV2("color_key_filter_v2"),
  clutFilter("clut_filter"),
  sharpnessFilter("sharpness_filter"),
  sharpnessFilterV2("sharpness_filter_v2"),
  chromaKeyFilter("chroma_key_filter"),
  chromaKeyFilterV2("chroma_key_filter_v2"),
  asyncDelayFilter("async_delay_filter"),
  noiseSuppressFilter("noise_suppress_filter"),
  noiseSuppressFilterV2("noise_suppress_filter_v2"),
  invertPolarityFilter("invert_polarity_filter"),
  noiseGateFilter("noise_gate_filter"),
  compressorFilter("compressor_filter"),
  limiterFilter("limiter_filter"),
  expanderFilter("expander_filter"),
  upwardCompressorFilter("upward_compressor_filter"),
  lumaKeyFilter("luma_key_filter"),
  lumaKeyFilterV2("luma_key_filter_v2"),
  vstFilter("vst_filter");

  final String value;

  const SourceFilterKind(this.value);
}

class ListenForAudioOBS {
  late WebSocketChannel _channel;
  late Function(List<AudioOutputStatus>) _onMessage;
  int _connectErrorCount = 0;

  Future<void> startSubscribeForAudio() async {
    print("Connecting to OBS WebSocket for listening to audio data");

    _channel = WebSocketChannel.connect(
      Uri.parse('ws://${ApplicationConfig.obsIp}:${ApplicationConfig.port}'),
    );
    print("Connected to OBS WebSocket for listening to audio data");
    _channel.stream.listen(
      (message) {
        Map<String, dynamic> jsonMessage = jsonDecode(message);

        int opCode = jsonMessage["op"] as int;
        if (opCode == 5) {
          // convert data message to json
          Map<String, dynamic> data;
          try {
            data = (jsonDecode(message) as Map<String, dynamic>)["d"]
                as Map<String, dynamic>;
          } catch (e) {
            print('Error while making data message: $e, message: $message');
            return;
          }
          Map<String, dynamic> eventData;
          try {
            eventData = data["eventData"] as Map<String, dynamic>;
          } catch (e) {
            print(
                'Error while making eventData message: $e, message: $message');
            return;
          }

          List<dynamic> inputs = eventData["inputs"] as List<dynamic>;

          List<AudioOutputStatus> audioOutputStatus = [];
          for (Map<String, dynamic> audioOutput in inputs) {
            String deviceName = audioOutput["inputName"].toString();
            String deviceUuid = audioOutput["inputUuid"].toString();
            List<dynamic> inputLevelsMul =
                audioOutput["inputLevelsMul"] as List<dynamic>;
            List<double> volume = [];
            for (List<dynamic> level in inputLevelsMul) {
              for (double item in level) {
                volume.add(item);
              }
            }

            audioOutputStatus.add(AudioOutputStatus(
                deviceName: deviceName,
                deviceUuid: deviceUuid,
                volume: volume));
          }

          _onMessage(audioOutputStatus);
        }
      },
      onError: (error) {
        print('Error: $error');
        _connectErrorCount++;
        if (_connectErrorCount < 20) {
          print('Reconnecting to OBS WebSocket');
          // try again in 500 milliseconds
          Future.delayed(const Duration(milliseconds: 500), () {
            startSubscribeForAudio();
          });
        } else {
          print('Failed to connect to OBS WebSocket');
        }
      },
      onDone: () {
        print('Connection closed');
      },
    );

    Map identifyMessage = {
      "op": 1,
      "d": {"rpcVersion": 1, "eventSubscriptions": 65536}
    };

    _channel.sink.add(jsonEncode(identifyMessage));
  }

  ListenForAudioOBS({required Function(List<AudioOutputStatus>) onMessage}) {
    _onMessage = onMessage;
    startSubscribeForAudio();
  }

  void close() {
    _channel.sink.close();
  }
}
