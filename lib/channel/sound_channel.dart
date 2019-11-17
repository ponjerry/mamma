import 'package:flutter/services.dart';

class SoundChannel {
  static const _channel = MethodChannel('com.papa.mamma/sound');

  static Future<void> record(bool enable) async {
    await _channel.invokeMethod('record', enable);
  }
}
