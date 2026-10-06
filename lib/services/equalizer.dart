import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mdlovfimusic/native_bindings/andrid_utils.dart';
import 'package:jni/jni.dart';

class EqualizerService {
  static const MethodChannel _channel = MethodChannel('com.merrmist.mdlovfimusic/equalizer');

  static bool openEqualizer(int sessionId) {
    if (GetPlatform.isAndroid) {
      try {
        JObject activity = JObject.fromReference(Jni.getCurrentActivity());
        JObject context = JObject.fromReference(Jni.getCachedApplicationContext());
        final success = Equalizer().openEqualizer(sessionId, context, activity);
        activity.release();
        context.release();
        return success;
      } catch (e) {
        print('Error calling openEqualizer: $e');
      }
    }
    return false;
  }

  static Future<void> initAudioEffect(int sessionId) async {
    if (GetPlatform.isAndroid) {
      try {
        await _channel.invokeMethod('initAudioEffect', {'sessionId': sessionId});
      } catch (e) {
        print('Error calling initAudioEffect: $e');
      }
    }
  }

  static Future<void> setBandGains(int sessionId, List<int> gainsMillibels) async {
    if (GetPlatform.isAndroid) {
      try {
        await _channel.invokeMethod('setBandGains', {
          'sessionId': sessionId,
          'gains': gainsMillibels,
        });
      } catch (e) {
        print('Error setting band gains: $e');
      }
    }
  }

  static Future<void> setBassBoost(int sessionId, int strength) async {
    if (GetPlatform.isAndroid) {
      try {
        await _channel.invokeMethod('setBassBoost', {
          'sessionId': sessionId,
          'strength': strength,
        });
      } catch (e) {
        print('Error setting bass boost: $e');
      }
    }
  }

  static Future<void> setLoudnessGain(int sessionId, int gainMb) async {
    if (GetPlatform.isAndroid) {
      try {
        await _channel.invokeMethod('setLoudnessGain', {
          'sessionId': sessionId,
          'gainMb': gainMb,
        });
      } catch (e) {
        print('Error setting loudness gain: $e');
      }
    }
  }

  static Future<void> endAudioEffect(int sessionId) async {
    if (GetPlatform.isAndroid) {
      try {
        await _channel.invokeMethod('endAudioEffect', {'sessionId': sessionId});
      } catch (e) {
        print('Error calling endAudioEffect: $e');
      }
    }
  }
}
