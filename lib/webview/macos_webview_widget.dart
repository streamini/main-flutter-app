import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class MacosWebviewWidget extends StatefulWidget {
  const MacosWebviewWidget({super.key});

  @override
  State<MacosWebviewWidget> createState() => MacosWebviewWidgetState();
}

class MacosWebviewWidgetState extends State<MacosWebviewWidget> {
  static const _myMacosView = "MySwiftUiView";
  static const platform = MethodChannel('com.example/my_channel');
  final GlobalKey _widgetKey = GlobalKey();
  List<Function(String)> jsCallbacks = [];
  Size? widgetSize;
  bool _isAlreadyLoadHtmlContent = false;

  bool get isAlreadyLoadHtmlContent => _isAlreadyLoadHtmlContent;
  List<ScrollData> scrollBlocks = [];
  List<Offset> dragBlocks = [];
  bool isPointerUpBlocked = false;
  bool isPointerDownBlocked = false;
  static const bool isEnablePointerBlockFuture = false;
  Offset? latestMousePosition;

  void _resizeView() {
    String widgetSizeString = const JsonEncoder().convert({'width': widgetSize!.width, 'height': widgetSize!.height});
    try {
      platform.invokeMethod('change_view_size', widgetSizeString).then((value) {});
    } on PlatformException catch (e) {
      throw Exception("Failed to send event: ${e.message}");
    }
  }

  double _getWidgetYPosition() {
    final RenderBox renderBox = _widgetKey.currentContext?.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    return position.dy;
  }

  Future<void> loadHtmlContent(String htmlContent) async {
    try {
      _isAlreadyLoadHtmlContent = true;
      await platform.invokeMethod('load_html_string', htmlContent);
    } on PlatformException catch (e) {
      throw Exception("Failed to send event: ${e.message}");
    }
  }

  Future<void> executeScript(String script) async {
    try {
      await platform.invokeMethod('execute_script', script);
    } on PlatformException catch (e) {
      throw Exception("Failed to send event: ${e.message}");
    }
  }

  Future<void> onJsCallback(Function(String) callback) async {
    jsCallbacks.add(callback);
  }

  @override
  void initState() {
    super.initState();
    platform.setMethodCallHandler(_handleMessageFromSwift);
  }

  Future<void> _handleMessageFromSwift(MethodCall call) async {
    switch (call.method) {
      case "callback_from_js":
        String message = call.arguments;

        for (Function callback in jsCallbacks) {
          callback(message);
        }
        break;
      default:
        throw Exception("Unknown method ${call.method}");
    }
  }

  @override
  Widget build(BuildContext context) {
    // widget x and y
    return LayoutBuilder(builder: (context, constraints) {
      double width = constraints.maxWidth;
      double height = constraints.maxHeight;
      widgetSize = Size(width, height);
      _resizeView();

      return Listener(
        onPointerUp: (event) {
          if (isPointerUpBlocked && isEnablePointerBlockFuture) {
            isPointerUpBlocked = false;
            return;
          } else {
            if (isEnablePointerBlockFuture) {
              isPointerDownBlocked = true;
            }

            // click up
            double x = event.localPosition.dx;
            double y = event.localPosition.dy + _getWidgetYPosition();

            latestMousePosition = Offset(x, y);

            Map<String, dynamic> params = {
              'x': x,
              'y': y,
            };

            String paramsString = const JsonEncoder().convert(params);

            try {
              platform.invokeMethod('click_up', paramsString);
            } on PlatformException catch (e) {
              throw Exception("Failed to send event: ${e.message}");
            }
          }
        },
        onPointerDown: (event) {
          if (isPointerDownBlocked && isEnablePointerBlockFuture) {
            isPointerDownBlocked = false;
            return;
          } else {
            latestMousePosition = event.localPosition;
            if (isEnablePointerBlockFuture) {
              isPointerUpBlocked = true;
            }

            double x = event.localPosition.dx;
            double y = event.localPosition.dy + _getWidgetYPosition();

            latestMousePosition = Offset(x, y);

            Map<String, dynamic> params = {
              'x': x,
              'y': y,
            };

            String paramsString = const JsonEncoder().convert(params);

            try {
              platform.invokeMethod('click_down', paramsString);
            } on PlatformException catch (e) {
              throw Exception("Failed to send event: ${e.message}");
            }
          }
        },

        // on scroll
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            double x = event.localPosition.dx;
            double y = event.localPosition.dy;
            double deltaY = event.scrollDelta.dy;

            scrollWheel(
                x, widgetSize!.height * (widgetSize!.height / (widgetSize!.height + _getWidgetYPosition())) - y, deltaY * -1);
          }
        },

        onPointerMove: (PointerMoveEvent event) {
          // check is pointer down
          double x = event.localPosition.dx;
          double y = widgetSize!.height - event.localPosition.dy; // + _getWidgetYPosition();
          Offset offset = Offset(x, y);

          if (dragBlocks.contains(offset)) {
            dragBlocks.remove(offset);
          } else {
            if (offset != latestMousePosition) {
              dragBlocks.add(offset);
              latestMousePosition = offset;
              Map<String, dynamic> params = {
                'x': x,
                'y': y,
              };

              String paramsString = const JsonEncoder().convert(params);

              try {
                platform.invokeMethod('mouse_drag', paramsString);
              } on PlatformException catch (e) {
                throw Exception("Failed to send event: ${e.message}");
              }
            }
          }
        },

        onPointerPanZoomUpdate: (event) {
          onPan(event);
        },

        child: Container(
          key: _widgetKey,
          // Step 2: Assign the GlobalKey
          width: width,
          height: height,
          color: Colors.blue,

          child: const AppKitView(
              viewType: _myMacosView,
              hitTestBehavior: PlatformViewHitTestBehavior.transparent,
              creationParams: {},
              creationParamsCodec: StandardMessageCodec()),
        ),
      );
    });
  }

  void scrollWheel(double x, double y, double deltaY) {
    ScrollData scrollData = ScrollData(x, y, deltaY);
    if (scrollBlocks.contains(scrollData)) {
      scrollBlocks.remove(scrollData);
    } else {
      scrollBlocks.add(scrollData);
      Map<String, dynamic> params = {
        'x': x,
        'y': y,
        'delta': deltaY,
      };

      String paramsString = const JsonEncoder().convert(params);

      try {
        platform.invokeMethod('mouse_scroll', paramsString);
      } on PlatformException catch (e) {
        throw Exception("Failed to send event: ${e.message}");
      }
    }
  }

  void onPan(PointerPanZoomUpdateEvent event) {
    scrollWheel(event.localPosition.dx, event.localPosition.dy, event.panDelta.dy);
  }
}

class ScrollData {
  double x;
  double y;
  double delta;

  ScrollData(this.x, this.y, this.delta);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ScrollData && other.x == x && other.y == y && other.delta == delta;
  }
}
