import 'dart:convert';
import 'dart:io';

import 'package:broadcast_gemini/webview/macos_webview_widget.dart';
import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';

class FlexibleUI extends StatefulWidget {
  const FlexibleUI({super.key});

  @override
  State<FlexibleUI> createState() => FlexibleUIState();
}

class FlexibleUIState extends State<FlexibleUI> {
  WebviewController? _windowsWebController;
  GlobalKey<MacosWebviewWidgetState>? _macosWebviewWidgetKey;

  FlexibleUIState() {
    if (Platform.isWindows) {
      _windowsWebController = WebviewController();
    } else if (Platform.isMacOS) {
      _macosWebviewWidgetKey = GlobalKey<MacosWebviewWidgetState>();
    } else {
      throw Exception("Platform not supported");
    }
  }

  Future<void> loadStringContent(String content) async {
    if (Platform.isWindows) {
      await _windowsWebController!.loadStringContent(content);
    } else if (Platform.isMacOS) {
      _macosWebviewWidgetKey!.currentState!.loadHtmlContent(content);
    } else {
      throw Exception("Platform not supported");
    }
  }

  Future<void> executeScript(String script) async {
    if (Platform.isWindows) {
      await _windowsWebController!.executeScript(script);
    } else if (Platform.isMacOS) {
      await _macosWebviewWidgetKey!.currentState!.executeScript(script);
    } else {
      throw Exception("Platform not supported");
    }
  }

  Future<void> initialize() async {
    if (Platform.isWindows) {
      await _windowsWebController!.initialize();
    } else if (Platform.isMacOS) {
    } else {
      throw Exception("Platform not supported");
    }
  }

  Future<void> addScriptToExecuteOnDocumentCreated(String script) async {
    if (Platform.isWindows) {
      await _windowsWebController!.addScriptToExecuteOnDocumentCreated(script);
    } else if (Platform.isMacOS) {
      await _macosWebviewWidgetKey!.currentState!.executeScript(script);
    } else {
      throw Exception("Platform not supported");
    }
  }

  void listenForWebMessage(Function(String event) callback) {
    if (Platform.isWindows) {
      _windowsWebController!.webMessage.listen((event) {
        Map<String, dynamic> response = {};

        String eventString = event.toString();
        Map<String, dynamic> eventMap = jsonDecode(eventString);

        for (var item in eventMap.entries) {
          if (item.key == "args") {
            response["args"] = item.value[0];
          } else {
            response[item.key] = item.value;
          }
        }

        callback.call(jsonEncode(response));
      });
    } else if (Platform.isMacOS) {
      _macosWebviewWidgetKey!.currentState!.onJsCallback((String event) {
        // convert event to map
        Map<String, dynamic> eventMap = jsonDecode(event);
        Map<String, dynamic> response = {};

        for (var key in eventMap.keys) {
          if (key == "args") {
            response[key] = eventMap[key][0];
          } else {
            response[key] = eventMap[key];
          }
        }

        callback.call(jsonEncode(response));
      });
    } else {
      throw Exception("Platform not supported");
    }
  }

  void sendSceneToWebView(String message) {
    executeScript('window.handleFlutterMessage("$message");');
  }

  void sendSourcesToWebView(String message) {
    executeScript('window.sendSourcesToWebView("$message");');
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
      return Container(
        child: _windowsWebController!.value.isInitialized ? Webview(_windowsWebController!) : const CircularProgressIndicator(),
      );
    } else if (Platform.isMacOS) {
      return Stack(
        children: [
          MacosWebviewWidget(
            key: _macosWebviewWidgetKey,
          ),
          // if (_macosWebviewWidgetKey?.currentState?.isAlreadyLoadHtmlContent == true) Container() else const CircularProgressIndicator(),
        ],
      );
    } else {
      throw Exception("Platform not supported");
    }
  }
}
