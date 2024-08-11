import 'dart:convert';

import 'package:flutter/services.dart';

const _platform = MethodChannel('com.example/my_channel');

Future<List<AudioDeviceItem>> getDeviceListMacOS() async {
  return await _platform.invokeMethod("get_device_list", {}).then((deviceListJsonString) {
    List<AudioDeviceItem> deviceList = [];

    // value is json string convert it to List<Map>
    List<dynamic> deviceListMap = jsonDecode(deviceListJsonString);
    for (var device in deviceListMap) {
      Map<String, String> deviceMap = Map<String, String>.from(device);
      deviceList.add(AudioDeviceItem(deviceName: deviceMap["name"]!, deviceId: deviceMap["id"]!));
    }
    return deviceList;
  });
}

class AudioDeviceItem {
  String deviceName;
  String deviceId;

  AudioDeviceItem({required this.deviceName, required this.deviceId});
}
