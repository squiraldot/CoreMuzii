import 'dart:convert';

import '/models/equalizer.dart';
import '/models/equalizer_preset.dart';

class EqualizerPresetFileCodec {
  static const String format = 'mdlovfi-eq';
  static const int version = 1;
  static const String extension = 'mdleq';
  static const String mimeType = 'application/json';

  static String encode(EqualizerPreset preset) {
    if (preset.isBuiltIn) {
      throw ArgumentError(
        'Built-in presets must be copied before exporting.',
      );
    }

    final config = preset.config;
    final document = <String, Object>{
      'format': format,
      'version': version,
      'name': preset.name,
      'author': preset.author,
      'description': preset.description,
      'enabled': config.enabled,
      'preamp': config.preampDb,
      'outputGain': config.outputGainDb,
      'limiterEnabled': config.limiterEnabled,
      'bands': config.bands
          .map((band) => <String, Object>{
                'type': band.type.value,
                'frequency': band.frequency,
                'gainDb': band.gainDb,
                'q': band.q,
                'enabled': band.enabled,
              })
          .toList(growable: false),
    };

    return const JsonEncoder.withIndent('  ').convert(document);
  }

  static EqualizerPreset decode(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) {
        throw const FormatException('Equalizer preset must be a JSON object');
      }

      final json = Map<String, Object?>.from(decoded);
      if (json['format'] != format) {
        throw const FormatException('Unsupported equalizer preset format');
      }

      final rawVersion = json['version'];
      if (rawVersion != version) {
        throw FormatException(
          'Unsupported equalizer preset version: $rawVersion',
        );
      }

      final rawBands = json['bands'];
      if (rawBands is! List) {
        throw const FormatException('Equalizer preset bands must be a list');
      }

      final bands = rawBands.map((rawBand) {
        if (rawBand is! Map) {
          throw const FormatException('Equalizer preset band must be an object');
        }
        final band = Map<String, Object?>.from(rawBand);
        return EqualizerBand(
          id: 'imported-${bands.length}',
          type: EqualizerFilterTypeJson.parse(band['type']),
          frequency: _readDouble(band, 'frequency'),
          gainDb: _readDouble(band, 'gainDb'),
          q: _readDouble(band, 'q'),
          enabled: _readBool(band, 'enabled'),
        );
      }).toList(growable: false);

      final config = EqualizerConfig(
        enabled: _readBool(json, 'enabled'),
        preampDb: _readDouble(json, 'preamp'),
        outputGainDb: _readOptionalDouble(json, 'outputGain', fallback: 0),
        limiterEnabled: _readOptionalBool(
          json,
          'limiterEnabled',
          fallback: true,
        ),
        bands: bands,
      );

      final now = DateTime.now().toUtc();
      return EqualizerPreset(
        id: 'imported-${now.microsecondsSinceEpoch}',
        name: _readString(json, 'name'),
        author: _readString(json, 'author'),
        description: _readOptionalString(json, 'description', fallback: ''),
        createdAt: now,
        updatedAt: now,
        isBuiltIn: false,
        config: config,
      );
    } on FormatException {
      rethrow;
    } on ArgumentError catch (error) {
      throw FormatException('Invalid equalizer preset: ${error.message}');
    } on TypeError catch (error) {
      throw FormatException('Invalid equalizer preset: $error');
    } on JsonUnsupportedObjectError catch (error) {
      throw FormatException('Invalid equalizer preset JSON: $error');
    } catch (error) {
      throw FormatException('Invalid equalizer preset: $error');
    }
  }

  static String _readString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw FormatException('Equalizer preset $key must be a non-empty string');
  }

  static String _readOptionalString(
    Map<String, Object?> json,
    String key, {
    required String fallback,
  }) {
    final value = json[key];
    if (value == null) return fallback;
    if (value is String) return value;
    throw FormatException('Equalizer preset $key must be a string');
  }

  static double _readDouble(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is num && value.isFinite) return value.toDouble();
    throw FormatException('Equalizer preset $key must be a finite number');
  }

  static double _readOptionalDouble(
    Map<String, Object?> json,
    String key, {
    required double fallback,
  }) {
    final value = json[key];
    if (value == null) return fallback;
    if (value is num && value.isFinite) return value.toDouble();
    throw FormatException('Equalizer preset $key must be a finite number');
  }

  static bool _readBool(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is bool) return value;
    throw FormatException('Equalizer preset $key must be a boolean');
  }

  static bool _readOptionalBool(
    Map<String, Object?> json,
    String key, {
    required bool fallback,
  }) {
    final value = json[key];
    if (value == null) return fallback;
    if (value is bool) return value;
    throw FormatException('Equalizer preset $key must be a boolean');
  }
}
