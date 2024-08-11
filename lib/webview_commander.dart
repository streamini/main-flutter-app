/*
* This file is collecting method that use to communicate with the webview.
* */

import 'package:broadcast_gemini/webview/flexible_ui.dart';
import 'package:flutter/material.dart';

class WebviewCommander {
  final GlobalKey<FlexibleUIState> _flexibleUiKey = GlobalKey<FlexibleUIState>();

  void addAudioDeviceToMixer(String deviceName, int deviceSettingVolume, double deviceEmittingVolume) {
    // TODO: Implement this method
  }

  void updateAudioDeviceVolume(int index, int settingVolume, double emittingVolume) {
    // TODO: Implement this method
  }

  void removeAudioDeviceFromMixer(int index) {
    // TODO: Implement this method
  }
}
