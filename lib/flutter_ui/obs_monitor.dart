import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:broadcast_gemini/backend/ObsAdaptorPro.dart';
import 'package:broadcast_gemini/flutter_ui/Input_alert.dart';
import 'package:yaml/yaml.dart';
import 'package:flutter/material.dart';
import 'package:camera_macos/camera_macos.dart';
import 'dart:math';
import 'package:webview_windows/webview_windows.dart';

class RectangleWidget2 extends StatefulWidget {
  final double width;
  final double height;
  final String scene;

  RectangleWidget2({required this.width, required this.height, required this.scene});

  @override
  _RectangleWidget2State createState() => _RectangleWidget2State();
}

class _RectangleWidget2State extends State<RectangleWidget2> {
  final GlobalKey cameraKey = GlobalKey();
  late CameraMacOSController macOSController;
  double ratio = 0.0;
  Set<GlobalKey<_DraggableResizableWidgetState>> widgetKeys = {};
  Future<String>? yamlData;
  final WebviewController? _windowsCameraWebviewController = (Platform.isWindows) ? WebviewController() : null;

  @override
  void initState() {
    super.initState();
    yamlData = loadYamlData();
    if (Platform.isWindows) {
      _initializeWebView();
    }
  }

  Future<void> _initializeWebView() async {
    await _windowsCameraWebviewController!.initialize();
    //Show https://mc.bhira.me
    await _windowsCameraWebviewController!.loadUrl('https://mc.bhira.me');
  }

  Future<WebviewPermissionDecision> _onPermissionRequested(String url, WebviewPermissionKind kind, bool isUserInitiated) async {
    final decision = await showDialog<WebviewPermissionDecision>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Permission requested'),
          content: Text('The website at $url requested the following permission: $kind'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(WebviewPermissionDecision.deny);
              },
              child: Text('Deny'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(WebviewPermissionDecision.allow);
              },
              child: Text('Allow'),
            ),
          ],
        );
      },
    );

    return decision ?? WebviewPermissionDecision.none;
  }

  @override
  Widget build(BuildContext context) {
    double adjustedWidth = widget.width;
    double adjustedHeight = widget.width * 9 / 16;

    if (adjustedHeight > widget.height) {
      adjustedHeight = widget.height;
      adjustedWidth = widget.height * 16 / 9;
    }

    ratio = 1920 / adjustedWidth;

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 50, 38, 55),
      body: GestureDetector(
        onTap: () {
          setState(() {
            widgetKeys.forEach((key) {
              key.currentState?.setTransparency(0.0);
            });
          });
        },
        child: Center(
          child: Container(
            width: adjustedWidth,
            height: adjustedHeight,
            color: Colors.grey[900],
            child: Stack(
              children: [
                if (Platform.isMacOS)
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: CameraMacOSView(
                      deviceId: "7626645E-4425-469E-9D8B-97E0FA59AC75",
                      cameraMode: CameraMacOSMode.photo,
                      onCameraInizialized: (CameraMacOSController controller) {
                        this.macOSController = controller;
                      },
                    ),
                  ),
                FutureBuilder(
                  future: yamlData,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData) {
                        List<Widget> widgets = generateWidgets(snapshot.data ?? '');
                        return Stack(
                          children: widgets,
                        );
                      } else {
                        return Center(child: Text('Failed to load widgets'));
                      }
                    } else {
                      return Center(child: CircularProgressIndicator());
                    }
                  },
                ),
                if (Platform.isWindows)
                  Container(
                    width: adjustedWidth,
                    height: adjustedHeight,
                    child: Webview(
                      _windowsCameraWebviewController!,
                      permissionRequested: _onPermissionRequested,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String> loadYamlData() async {
    var crScene = await getCurrentScene();
    var json6 = await getsourceslist(crScene);
    return json6;
  }

  List<Widget> generateWidgets(String yamlString) {
    final dynamic yamlMap = loadYaml(yamlString);
    final String jsonString2 = jsonEncode(yamlMap);
    Map<String, dynamic> jsonMap = jsonDecode(jsonString2);

    List<dynamic> sceneItems = jsonMap['sceneItems'];

    List<Widget> widgets = [];
    for (var item in sceneItems) {
      GlobalKey<_DraggableResizableWidgetState> key = GlobalKey<_DraggableResizableWidgetState>();
      widgetKeys.add(key);

      double originalWidth = item['sceneItemTransform']['width'].toDouble();
      double originalHeight = item['sceneItemTransform']['height'].toDouble();
      double originalScaleX = item['sceneItemTransform']['scaleX'].toDouble();
      double originalScaleY = item['sceneItemTransform']['scaleY'].toDouble();

      widgets.add(
        DraggableResizableWidget(
          key: key,
          width: originalWidth / ratio,
          height: originalHeight / ratio,
          left: item['sceneItemTransform']['positionX'].toDouble() / ratio,
          top: item['sceneItemTransform']['positionY'].toDouble() / ratio,
          text: item['sourceName'],
          color: Colors.blue,
          sourceName: item['sourceName'],
          scaleX: item['sceneItemTransform']['scaleX'].toDouble() / ratio,
          scaleY: item['sceneItemTransform']['scaleY'].toDouble() / ratio,
          sceneItemId: item['sceneItemId'],
          ratio: ratio,
          originalWidth: originalWidth,
          originalHeight: originalHeight,
          originalScaleX: originalScaleX,
          originalScaleY: originalScaleY,
          onTap: (key) {
            setState(() {
              widgetKeys.forEach((k) {
                k.currentState?.setTransparency(k == key ? 0.5 : 0.0);
              });
            });
          },
        ),
      );
    }
    return widgets;
  }
}

class DraggableResizableWidget extends StatefulWidget {
  final double width;
  final double height;
  final double left;
  final double top;
  final String text;
  final Color color;
  final String sourceName;
  final double scaleX;
  final double scaleY;
  final int sceneItemId;
  final double ratio;
  final double originalWidth;
  final double originalHeight;
  final double originalScaleX;
  final double originalScaleY;
  final Function(GlobalKey<_DraggableResizableWidgetState>) onTap;

  const DraggableResizableWidget({
    Key? key,
    required this.width,
    required this.height,
    required this.left,
    required this.top,
    required this.text,
    required this.color,
    required this.sourceName,
    required this.scaleX,
    required this.scaleY,
    required this.sceneItemId,
    required this.ratio,
    required this.originalWidth,
    required this.originalHeight,
    required this.originalScaleX,
    required this.originalScaleY,
    required this.onTap,
  }) : super(key: key);

  @override
  _DraggableResizableWidgetState createState() => _DraggableResizableWidgetState();
}

class _DraggableResizableWidgetState extends State<DraggableResizableWidget> {
  late double width;
  late double height;
  late double left;
  late double top;
  late double scaleX;
  late double scaleY;
  late int sceneItemId;
  late double ratio;
  late double originalWidth;
  late double originalHeight;
  late double originalScaleX;
  late double originalScaleY;
  double transparent = 0.0;

  @override
  void initState() {
    super.initState();
    width = widget.width;
    height = widget.height;
    left = widget.left;
    top = widget.top;
    scaleX = widget.scaleX;
    scaleY = widget.scaleY;
    sceneItemId = widget.sceneItemId;
    ratio = widget.ratio;
    originalWidth = widget.originalWidth;
    originalHeight = widget.originalHeight;
    originalScaleX = widget.originalScaleX;
    originalScaleY = widget.originalScaleY;
  }

  Future<void> updateOBS() async {
    final sourcescaleX = originalScaleX;
    final sourcescaleY = originalScaleY;

    final widght2 = width * ratio;
    final height2 = height * ratio;
    final obsPositionX = left * ratio;
    final obsPositionY = top * ratio;

    final newScaleX = widght2 / originalWidth;
    final newScaleY = height2 / originalHeight;

    print('Updating OBS:');
    print('Scene Item ID: $sceneItemId');
    print("original width: $originalWidth, original height: $originalHeight");
    final scenenow = await getCurrentScene();

    updateinputOBS(scenenow, sourcescaleX * newScaleX, sourcescaleY * newScaleY, obsPositionX, obsPositionY, sceneItemId);
  }

  void setTransparency(double value) {
    setState(() {
      transparent = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          widget.onTap(widget.key as GlobalKey<_DraggableResizableWidgetState>);
        },
        onPanUpdate: (details) {
          setState(() {
            left += details.delta.dx;
            top += details.delta.dy;
            transparent = 0.5;
          });
        },
        onPanEnd: (details) {
          updateOBS();
        },
        child: Stack(
          children: [
            Container(
              width: width,
              height: height,
              color: widget.color.withOpacity(transparent),
              child: Center(
                  child: Text(
                widget.text,
                style: TextStyle(
                  color: Colors.white.withOpacity(transparent), // Semi-transparent white
                ),
              )),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: buildResizeButton(Alignment.bottomRight),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildResizeButton(Alignment alignment) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          switch (alignment) {
            case Alignment.bottomRight:
              width += details.delta.dx;
              height += details.delta.dy;
              break;
            default:
              break;
          }
        });
      },
      onPanEnd: (details) {
        updateOBS();
      },
      child: Container(
        width: 10,
        height: 10,
        color: Colors.white.withOpacity(transparent),
      ),
    );
  }
}
