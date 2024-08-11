import 'dart:convert';
import 'package:broadcast_gemini/ai_feature/ai_presentation.dart';
import 'package:broadcast_gemini/ai_feature/change_ui_with_gemini.dart';
import 'package:broadcast_gemini/backend/terminal.dart';
import 'package:broadcast_gemini/config.dart';
import 'package:broadcast_gemini/flutter_ui/Input_alert.dart';
import 'package:broadcast_gemini/backend/ObsAdaptorPro.dart';
import 'package:broadcast_gemini/flutter_ui/obs_monitor.dart';
import 'package:broadcast_gemini/flutter_ui/scene_alert.dart';
import 'package:broadcast_gemini/models/audio_output_status.dart';
import 'package:broadcast_gemini/webview/flexible_ui.dart';
import 'package:broadcast_gemini/menubar.dart';
import 'package:broadcast_gemini/webview_commander.dart';
import 'package:flutter/material.dart';
import 'package:menu_bar/menu_bar.dart';
import "package:http/http.dart" as http;
import 'dart:async';
import 'package:flutter_window_close/flutter_window_close.dart';

final GlobalKey<FlexibleUIState> _flexibleUiKey = GlobalKey<FlexibleUIState>();

bool isVisible = true;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String? htmlContent;

  bool isGeneratingUi = false;

  final changeUITextFieldController = TextEditingController();
  Offset? _displayViewPosition;
  Size? _displayViewSize;
  WebviewCommander webviewCommander = WebviewCommander();
  List<AudioOutputStatus> audioOutputStatuses = [];

  @override
  void initState() {
    super.initState();

    if (ApplicationConfig.isAutoStartOBS) {
      runObsCommand();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      flexibleUiKey = _flexibleUiKey;
      initPlatformState();

      String output = "";
      runPythonCode("dry_run.py", (value) {
        print("python output: $value");
        output += value;
      }, context)
          .then((value) {
        print(output);
      });
    });

    FlutterWindowClose.setWindowShouldCloseHandler(() async {
      print("Window should close");
      bool alreadyExitApp = false;

      // Set timeout for 3 seconds
      var timeout = const Duration(seconds: 3);

      // Create a completer to handle the timeout
      Completer<bool> completer = Completer();

      // Set a timeout to complete the completer with true if not already completed
      Future.delayed(timeout, () {
        if (!alreadyExitApp) {
          print("Timeout");
          completer.complete(true);
        }
      });

      // Call shutdownObs and complete the completer with true when done
      shutdownObs().then((value) {
        alreadyExitApp = true;
        completer.complete(true);
      });

      // Return the result of the completer
      return completer.future;
    });
  }

  Future<String> loadHTMLContent() async {
    const String url =
        'https://firestore.googleapis.com/v1/projects/gemini-broadcast/databases/(default)/documents/web_content/default';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      print('Failed to load document');
    }

    Map<String, dynamic> data = jsonDecode(response.body);

    String htmlContent = data['fields']['1']['stringValue'];

    return htmlContent;
  }

  Future<void> initPlatformState() async {
    // await runObsCommand();
    // Your initialization code here
    // showAlertDialog(context);
    // await Future.delayed(Duration(seconds: 5)); // Simulate a delay

    await _flexibleUiKey.currentState!.initialize();

    await loadHTMLContent().then((value) async {
      htmlContent = value;
      await _flexibleUiKey.currentState!.loadStringContent(htmlContent!);

      // Set up the message handler
      _flexibleUiKey.currentState!.listenForWebMessage((event) {
        // Decode the event string directly
        final data = json.decode(event) as Map<String, dynamic>;
        handleJavaScriptCall(data);
      });
      setState(() {});
    });

    setState(() {
      obsconnected = true;
    });

    obsAdaptor.getOnConnectCallbacks(() async {
      // wait for 2 second
      await Future.delayed(const Duration(seconds: 2));
      await startvirtualcamera();
      await getobsinfo();

      ListenForAudioOBS(onMessage: (audioOutputStatusList) {
        // check is it different to the current audioOutputStatuses
        bool isDifferent = false;
        for (var audioOutputStatus in audioOutputStatusList) {
          if (!audioOutputStatuses.contains(audioOutputStatus)) {
            isDifferent = true;
            break;
          }
        }

        if (isDifferent) {
          // check is it have new device
          for (var audioOutputStatus in audioOutputStatusList) {
            // if device ID is not in the list, add it
            if (!audioOutputStatuses.any((element) =>
                element.deviceUuid == audioOutputStatus.deviceUuid)) {
              audioOutputStatuses.add(audioOutputStatus);
              webviewCommander.addAudioDeviceToMixer(
                  audioOutputStatus.deviceName,
                  50,
                  audioOutputStatus.getMaxVolume());
            }
          }

          // check it have removed device
          for (var audioOutputStatus in audioOutputStatuses) {
            // if device ID is not in the list, remove it
            if (!audioOutputStatusList.any((element) =>
                element.deviceUuid == audioOutputStatus.deviceUuid)) {
              audioOutputStatuses.remove(audioOutputStatus);
              // index
              webviewCommander.removeAudioDeviceFromMixer(
                  audioOutputStatusList.indexOf(audioOutputStatus));
            }
          }

          // check is have any device update
          for (var audioOutputStatus in audioOutputStatusList) {
            // if device ID is in the list, update it
            if (audioOutputStatuses.any((element) =>
                element.deviceUuid == audioOutputStatus.deviceUuid)) {
              // if volume or current volume is different, update it
              var currentAudioOutputStatus = audioOutputStatuses.firstWhere(
                  (element) =>
                      element.deviceUuid == audioOutputStatus.deviceUuid);
              if (currentAudioOutputStatus.volume != audioOutputStatus.volume ||
                  currentAudioOutputStatus.volume != audioOutputStatus.volume) {
                audioOutputStatuses.remove(currentAudioOutputStatus);
                audioOutputStatuses.add(audioOutputStatus);
                webviewCommander.updateAudioDeviceVolume(
                    audioOutputStatusList.indexOf(audioOutputStatus),
                    50,
                    audioOutputStatus.getMaxVolume());
              }
            }
          }
        }
      });
    });
  }

  var obsconnected = false;
  var currentScene = "";
  var currentSource = "";

  void handleJavaScriptCall(Map<String, dynamic> data) async {
    String methodName = data['handlerName'];
    switch (methodName) {
      case 'changeui':
        setState(() {
          isVisible = !isVisible;
        });
        break;
      case 'start_streaming':
        print("Start streaming");
        await handleStartStreaming();
        break;
      case 'start_recording':
        await handleStartRecording();
        break;
      case 'add_sources':
        var crScene = await getCurrentScene();

        await showOptionsDialog(context, crScene);

        break;
      case 'add_scene':
        await showAddSceneDialog(context);
        await getobsinfo();

        break;
      case 'remove_scene':
        await showDeleteConfirmationDialog(context, currentScene);
        await getobsinfo();
        break;
      case 'remove_sources':
        print(currentSource);
        await removeSource(currentSource);
        break;
      case 'sceneSelectedHandler':
        print(data['args']);
        currentScene = data['args'];
        var json6 = await getsourceslist(currentScene);
        _flexibleUiKey.currentState!.sendSourcesToWebView(json6);
        setCurrentProgramScene(currentScene);
        setState(() {
          currentScene = currentScene;
        });
        break;
      case 'main_display_position_change':
        String message = data["args"];
        Map<String, dynamic> position =
            json.decode(message) as Map<String, dynamic>;
        double x = double.tryParse(position["x"].toString())!;
        double y = double.tryParse(position["y"].toString())!;
        double width = double.tryParse(position["width"].toString())!;
        double height = double.tryParse(position["height"].toString())!;

        setState(() {
          _displayViewPosition = Offset(x, y);
          _displayViewSize = Size(width, height);
        });

        break;
      case 'sourceSelectedHandler':
        print(data['args'][0]);
        currentSource = data['args'][0];
        break;

      case 'liveassistant':
        String output = "";
        runPythonCode("live_assistant.py", (value) {
          print("python output: $value");
          output += value;
        }, context)
            .then((value) {
          print(output);
        });

        break;
      default:
        print("Unknown method: $methodName");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        menuTheme: const MenuThemeData(
          style: MenuStyle(
            padding:
                WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 16.0)),
          ),
        ),
      ),
      home: MenuBarWidget(
        barButtons: menuBarButtons(context),
        barStyle: const MenuStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.zero),
          backgroundColor: WidgetStatePropertyAll(Color(0xFF2b2b2b)),
          maximumSize: WidgetStatePropertyAll(Size(double.infinity, 28.0)),
        ),
        barButtonStyle: const ButtonStyle(
          padding:
              WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6.0)),
          minimumSize: WidgetStatePropertyAll(Size(0.0, 32.0)),
        ),
        menuButtonStyle: const ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size.fromHeight(36.0)),
          padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0)),
        ),
        enabled: true,
        child: Scaffold(
          body: Column(
            children: [
              if (isVisible) ...[
                Container(
                  height: 60,
                  color: Colors.grey[900],
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Text(
                        "Change UI",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 20),
                      // Add some spacing between the Text and the TextField
                      Expanded(
                        // Make the TextField take up the remaining space in the Row
                        child: Container(
                          height: 40.0, // Set the height
                          child: TextField(
                            controller: changeUITextFieldController,
                            decoration: InputDecoration(
                              hintText: "Enter prompt",
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 14.0),
                            ),
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Add some spacing between the TextField and the Button
                      Container(
                        height: 40.0, // Set the height
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 14.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          onPressed: () async {
                            String text = changeUITextFieldController.text;
                            if (htmlContent != null && text.isNotEmpty) {
                              print("Start change UI");
                              isGeneratingUi = true;
                              setState(() {});
                              print(
                                  "current state: ${_flexibleUiKey.currentState}");
                              var value =
                                  await changeUIWithGemini(htmlContent!, text);

                              isGeneratingUi = false;
                              print("Value");
                              _flexibleUiKey.currentState!
                                  .loadStringContent(value);
                              setState(() {});
                              await getObsInfo();
                            } else if (htmlContent == null) {
                              print("htmlContent is null");
                            } else {
                              SnackBar(content: Text("Please enter a prompt"));
                            }
                          },
                          child: Text(
                            "Generate",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Expanded(
                child: Stack(
                  children: [
                    Stack(
                      children: [
                        FlexibleUI(key: _flexibleUiKey),
                        if (obsconnected == true &&
                            _displayViewPosition != null &&
                            _displayViewSize != null) ...[
                          Positioned(
                            left: _displayViewPosition!.dx,
                            top: _displayViewPosition!.dy,
                            child: SizedBox(
                              width: _displayViewSize!.width,
                              height: _displayViewSize!.height,
                              child: LayoutBuilder(
                                builder: (BuildContext context,
                                    BoxConstraints constraints) {
                                  return RectangleWidget2(
                                    width: _displayViewSize!.width,
                                    height: _displayViewSize!.height,
                                    scene: currentScene,
                                  );
                                },
                              ),
                            ),
                          )
                        ],
                        (isGeneratingUi)
                            ? Container(
                                color: Colors.black.withOpacity(0.5),
                                child: Center(
                                  child: Container(
                                    // max width 300 height 300
                                    constraints: const BoxConstraints(
                                        maxWidth: 300, maxHeight: 300),
                                    child: const Column(
                                      children: [
                                        Text("Generating UI"),
                                        CircularProgressIndicator(),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
