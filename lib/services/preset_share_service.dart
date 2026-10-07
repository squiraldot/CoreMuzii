import 'dart:async';

import 'package:flutter/services.dart';

class PresetShareService {
  static const _channel = MethodChannel('mdlovfi/preset_share_method');

  static Future<String?> getInitialPreset() {
    return _channel.invokeMethod<String>('getInitialPreset');
  }

  static Stream<String> get incomingPresets {
    return _channel
        .receiveBroadcastStream()
        .where((value) => value is String)
        .cast<String>();
  }
}
