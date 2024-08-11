import 'dart:math';

class AudioOutputStatus {
  String deviceName;
  String deviceUuid;
  List<double> volume;

  AudioOutputStatus({required this.deviceName, required this.deviceUuid, required this.volume});

  double getMaxVolume() {
    if (volume.isEmpty) {
      return 0;
    }

    return volume.reduce(max);
  }

  @override
  String toString() {
    return 'AudioOutputStatus{deviceName: $deviceName, deviceUuid: $deviceUuid, volume: ${getMaxVolume()}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AudioOutputStatus &&
      other.deviceName == deviceName &&
      other.deviceUuid == deviceUuid &&
      other.volume == volume;
  }
}