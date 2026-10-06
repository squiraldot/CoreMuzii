import 'dart:convert';

import 'package:jni/jni.dart';
import 'package:mdlovfimusic/native_bindings/andrid_utils.dart';

import '../models/equalizer.dart';

class EqualizerService {
  static bool openEqualizer(int sessionId) {
    JObject activity = JObject.fromReference(Jni.getCurrentActivity());
    JObject context = JObject.fromReference(Jni.getCachedApplicationContext());
    final success = Equalizer().openEqualizer(sessionId, context, activity);
    activity.release();
    context.release();
    return success;
  }

  static bool applyConfig(int sessionId, EqualizerConfig config) {
    if (sessionId <= 0) return false;

    final context = jsonEncode(config.toJson()).toJString();
    try {
      return Equalizer().applyEqualizerConfig(sessionId, context);
    } finally {
      context.release();
    }
  }

  static void initAudioEffect(int sessionId) {
    JObject context = JObject.fromReference(Jni.getCachedApplicationContext());
    Equalizer().initAudioEffect(sessionId, context);
    context.release();
  }

  static void endAudioEffect(int sessionId) {
    JObject context = JObject.fromReference(Jni.getCachedApplicationContext());
    Equalizer().endAudioEffect(sessionId, context);
    context.release();
  }
}
