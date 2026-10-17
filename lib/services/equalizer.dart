import 'dart:convert';

import 'package:jni/jni.dart';
import 'package:mdlovfimusic/native_bindings/andrid_utils.dart';

import '../models/equalizer.dart';

class EqualizerApplyGate {
  int? _sessionId;
  String? _configJson;

  bool shouldApply(int sessionId, String configJson) {
    return _sessionId != sessionId || _configJson != configJson;
  }

  void markApplied(int sessionId, String configJson) {
    _sessionId = sessionId;
    _configJson = configJson;
  }

  void clearSession(int sessionId) {
    if (_sessionId == sessionId) {
      _sessionId = null;
      _configJson = null;
    }
  }
}

class EqualizerService {
  static Equalizer? _equalizer;
  static final EqualizerApplyGate _applyGate = EqualizerApplyGate();
  static int? _activeSessionId;

  static int? get activeSessionId => _activeSessionId;

  static Equalizer get _instance => _equalizer ??= Equalizer();

  static bool openEqualizer(int sessionId) {
    final activity = JObject.fromReference(Jni.getCurrentActivity());
    try {
      final context = JObject.fromReference(Jni.getCachedApplicationContext());
      try {
        return _instance.openEqualizer(sessionId, context, activity);
      } finally {
        context.release();
      }
    } finally {
      activity.release();
    }
  }

  static bool applyConfig(int sessionId, EqualizerConfig config) {
    if (sessionId <= 0) return false;

    final configJson = jsonEncode(config.toJson());
    if (!_applyGate.shouldApply(sessionId, configJson)) {
      return true;
    }

    final context = configJson.toJString();
    try {
      final success = _instance.applyEqualizerConfig(sessionId, context);
      if (success) {
        _applyGate.markApplied(sessionId, configJson);
      }
      return success;
    } finally {
      context.release();
    }
  }

  static void initAudioEffect(int sessionId) {
    final context = JObject.fromReference(Jni.getCachedApplicationContext());
    try {
      _instance.initAudioEffect(sessionId, context);
      _activeSessionId = sessionId;
    } finally {
      context.release();
    }
  }

  static void endAudioEffect(int sessionId) {
    if (_activeSessionId == sessionId) _activeSessionId = null;
    _applyGate.clearSession(sessionId);

    final context = JObject.fromReference(Jni.getCachedApplicationContext());
    try {
      _instance.endAudioEffect(sessionId, context);
    } finally {
      context.release();
    }
  }
}
