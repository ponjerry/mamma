import 'package:flutter/services.dart';

class SoundChannel {
  /* Singleton preset */
  static final SoundChannel _singleton = SoundChannel._internal();
  factory SoundChannel() => _singleton;
  SoundChannel._internal();
  /* End Singleton preset */

  static const BASE_CHANNEL = 'com.papa.mamma/sound';
  static const _methodChannel = MethodChannel('$BASE_CHANNEL');
  Stream<bool> speakingStateStream = const EventChannel('$BASE_CHANNEL/speaking').receiveBroadcastStream().cast<bool>();

  static Future<void> record(bool enable) async {
    await _methodChannel.invokeMethod('record', enable);
  }
}
