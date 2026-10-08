import 'package:flutter_test/flutter_test.dart';

Map<dynamic, dynamic> getStreamInfo(
    dynamic dbStreamData, dynamic downloadData, dynamic qualitySetting) {
  final nullVal = <dynamic, dynamic>{
    "audioCodec": null,
    "bitrate": null,
    "loudnessDb": null,
    "approxDurationMs": null
  };

  if (downloadData != null) {
    if (downloadData is Map &&
        downloadData["streamInfo"] is List &&
        (downloadData["streamInfo"] as List).length > 1) {
      final info = downloadData["streamInfo"][1];
      if (info is Map) {
        return info;
      }
    }
    return nullVal;
  }

  if (dbStreamData is Map) {
    final qualityKey =
        qualitySetting == 0 ? 'lowQualityAudio' : 'highQualityAudio';
    final audioData = dbStreamData[qualityKey];
    if (audioData is Map) {
      return audioData;
    }
    final fallbackKey =
        qualitySetting == 0 ? 'highQualityAudio' : 'lowQualityAudio';
    final fallbackAudioData = dbStreamData[fallbackKey];
    if (fallbackAudioData is Map) {
      return fallbackAudioData;
    }
  }

  return nullVal;
}

void main() {
  group('getStreamInfo defensive tests', () {
    test('returns highQualityAudio when available and streamingQuality is 1',
        () {
      final dbStreamData = {
        'playable': true,
        'highQualityAudio': {'audioCodec': 'Codec.opus', 'bitrate': 256000},
        'lowQualityAudio': {'audioCodec': 'Codec.mp4a', 'bitrate': 128000},
      };

      final result = getStreamInfo(dbStreamData, null, 1);
      expect(result['audioCodec'], equals('Codec.opus'));
      expect(result['bitrate'], equals(256000));
    });

    test('falls back to lowQualityAudio if highQualityAudio is null', () {
      final dbStreamData = {
        'playable': true,
        'highQualityAudio': null,
        'lowQualityAudio': {'audioCodec': 'Codec.mp4a', 'bitrate': 128000},
      };

      final result = getStreamInfo(dbStreamData, null, 1);
      expect(result['audioCodec'], equals('Codec.mp4a'));
      expect(result['bitrate'], equals(128000));
    });

    test('returns nullVal when all quality streams are null', () {
      final dbStreamData = {
        'playable': false,
        'highQualityAudio': null,
        'lowQualityAudio': null,
      };

      final result = getStreamInfo(dbStreamData, null, 1);
      expect(result, isA<Map>());
      expect(result['audioCodec'], isNull);
      expect(result['bitrate'], isNull);
    });

    test('handles corrupted download streamInfo gracefully', () {
      final downloadData = {
        'streamInfo': [true, null],
      };

      final result = getStreamInfo(null, downloadData, 1);
      expect(result, isA<Map>());
      expect(result['audioCodec'], isNull);
    });

    test('handles non-List download streamInfo gracefully', () {
      final downloadData = {
        'streamInfo': 'corrupted_string',
      };

      final result = getStreamInfo(null, downloadData, 1);
      expect(result, isA<Map>());
      expect(result['audioCodec'], isNull);
    });
  });
}
