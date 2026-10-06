import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mdlovfimusic/models/equalizer.dart';
import 'package:mdlovfimusic/models/equalizer_preset.dart';
import 'package:mdlovfimusic/services/equalizer_preset_file_codec.dart';

void main() {
  final baseConfig = EqualizerConfig.graphic10Band().copyWith(
    enabled: true,
    preampDb: -3,
    outputGainDb: 1.5,
    limiterEnabled: true,
  );

  test('exports a portable v1 mdleq document and imports it losslessly', () {
    final preset = EqualizerPreset(
      id: 'custom-1',
      name: 'My Bass',
      author: 'User',
      description: 'Test preset',
      createdAt: DateTime.utc(2026, 1, 2),
      updatedAt: DateTime.utc(2026, 1, 3),
      isBuiltIn: false,
      config: baseConfig,
    );

    final encoded = EqualizerPresetFileCodec.encode(preset);
    final json = jsonDecode(encoded) as Map<String, Object?>;

    expect(json['format'], 'mdlovfi-eq');
    expect(json['version'], 1);
    expect(json['name'], 'My Bass');
    expect(json['author'], 'User');
    expect(json.containsKey('id'), isFalse);
    expect(json.containsKey('createdAt'), isFalse);

    final imported = EqualizerPresetFileCodec.decode(encoded);

    expect(imported.name, preset.name);
    expect(imported.author, preset.author);
    expect(imported.description, preset.description);
    expect(imported.isBuiltIn, isFalse);
    expect(imported.config, equals(preset.config));
  });


  test('exports built-in presets without making the portable file mutable', () {
    final builtIn = EqualizerBuiltInPresets.all.first;

    final encoded = EqualizerPresetFileCodec.encode(builtIn);
    final imported = EqualizerPresetFileCodec.decode(encoded);

    expect(imported.isBuiltIn, isFalse);
    expect(imported.name, builtIn.name);
    expect(imported.config, equals(builtIn.config));
  });

  test('rejects malformed json and unsupported formats', () {
    expect(
      () => EqualizerPresetFileCodec.decode('{broken'),
      throwsA(isA<FormatException>()),
    );

    expect(
      () => EqualizerPresetFileCodec.decode(
        jsonEncode({'format': 'other-eq', 'version': 1}),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects future schema versions instead of silently misreading them', () {
    expect(
      () => EqualizerPresetFileCodec.decode(
        jsonEncode({
          'format': 'mdlovfi-eq',
          'version': 2,
          'name': 'Future',
          'author': 'Someone',
          'enabled': true,
          'preamp': 0,
          'bands': <Object?>[],
        }),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Unsupported equalizer preset version'),
        ),
      ),
    );
  });

  test('rejects invalid numeric values through the shared EQ validation', () {
    expect(
      () => EqualizerPresetFileCodec.decode(
        jsonEncode({
          'format': 'mdlovfi-eq',
          'version': 1,
          'name': 'Unsafe',
          'author': 'User',
          'enabled': true,
          'preamp': 999,
          'bands': <Object?>[],
        }),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('imports optional v1 fields with safe defaults for forward-compatible files',
      () {
    final imported = EqualizerPresetFileCodec.decode(
      jsonEncode({
        'format': 'mdlovfi-eq',
        'version': 1,
        'name': 'Minimal',
        'author': 'User',
        'enabled': true,
        'preamp': 0,
        'bands': [
          {
            'type': 'peaking',
            'frequency': 1000,
            'gainDb': 2,
            'q': 1,
            'enabled': true,
          },
        ],
      }),
    );

    expect(imported.config.outputGainDb, 0);
    expect(imported.config.limiterEnabled, true);
    expect(imported.config.bands.single.frequency, 1000);
  });
}
