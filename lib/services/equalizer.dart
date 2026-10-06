import 'dart:convert';

import 'package:jni/jni.dart';
import 'package:mdlovfimusic/native_bindings/andrid_utils.dart';

import '../models/equalizer.dart';

class EqualizerService {
  static final Equalizer _equalizer = Equalizer();
  static int? _appliedSessionId;
  static String? _appliedConfigJson;

  static bool openEqualizer(int sessionId) {
    JObject activity = JObject.fromReference(Jni.getCurrentActivity());
    JObject context = JObject.fromReference(Jni.getCachedApplicationContext());
    final success = _equalizer.openEqualizer(sessionId, context, activity);
    activity.release();
    context.release();
    return success;
  }

  static bool applyConfig(int sessionId, EqualizerConfig config) {
    if (sessionId <= 0) return false;

    final configJson = jsonEncode(config.toJson());
    if (_appliedSessionId == sessionId && _appliedConfigJson == configJson) {
      return true;
    }

    final context = configJson.toJString();
    try {
      final success = _equalizer.applyEqualizerConfig(sessionId, context);
      if (success) {
        _appliedSessionId = sessionId;
        _appliedConfigJson = configJson;
      }
      return success;
    } finally {
      context.release();
    }
  }

  static void initAudioEffect(int sessionId) {
    JObject context = JObject.fromReference(Jni.getCachedApplicationContext());
    _equalizer.initAudioEffect(sessionId, context);
    context.release();
  }

  static void endAudioEffect(int sessionId) {
    JObject context = JObject.fromReference(Jni.getCachedApplicationContext());
    _equalizer.endAudioEffect(sessionId, context);
    if (_appliedSessionId == sessionId) {
      _appliedSessionId = null;
      _appliedConfigJson = null;
    }
    context.release();
  }
}
