import 'package:flutter_test/flutter_test.dart';
import 'package:mdlovfimusic/models/equalizer_model.dart';
import 'package:mdlovfimusic/services/biquad_dsp.dart';

void main() {
  group('EQ Models and .mdleq Format Tests', () {
    test('EQBand serialization and copyWith', () {
      final band = EQBand(
        id: 'band_1',
        type: FilterType.peaking,
        frequency: 1000.0,
        gainDb: 3.5,
        q: 1.414,
        enabled: true,
      );

      final json = band.toJson();
      expect(json['frequency'], 1000.0);
      expect(json['gainDb'], 3.5);

      final restored = EQBand.fromJson(json);
      expect(restored.id, 'band_1');
      expect(restored.type, FilterType.peaking);
      expect(restored.frequency, 1000.0);
      expect(restored.gainDb, 3.5);

      final modified = band.copyWith(gainDb: -2.0);
      expect(modified.gainDb, -2.0);
      expect(modified.frequency, 1000.0);
    });

    test('EQPreset .mdleq JSON export and import', () {
      final preset = EQPreset(
        id: 'test_preset_1',
        name: 'Test Bass Boost',
        author: 'Tester',
        description: 'Unit test preset',
        preampDb: -3.0,
        bands: [
          EQBand(id: 'b1', frequency: 60.0, gainDb: 6.0),
          EQBand(id: 'b2', frequency: 1000.0, gainDb: 0.0),
        ],
      );

      final mdleqJson = preset.toMdleqJson();
      expect(mdleqJson['format'], 'mdlovfi-eq');
      expect(mdleqJson['version'], 1);
      expect(mdleqJson['name'], 'Test Bass Boost');
      expect(mdleqJson['preamp'], -3.0);

      final imported = EQPreset.fromMdleqJson(mdleqJson);
      expect(imported.name, 'Test Bass Boost');
      expect(imported.preampDb, -3.0);
      expect(imported.bands.length, 2);
      expect(imported.bands.first.frequency, 60.0);
      expect(imported.bands.first.gainDb, 6.0);
    });

    test('Invalid .mdleq schema throws FormatException', () {
      expect(
        () => EQPreset.fromMdleqJson({'format': 'wrong_format'}),
        throwsFormatException,
      );
    });
  });

  group('Biquad DSP Coefficient Tests', () {
    test('Flat peaking filter has ~0 dB response', () {
      final coeffs = AudioEQCookbook.calculate(
        type: FilterType.peaking,
        frequency: 1000.0,
        gainDb: 0.0,
        q: 1.414,
      );

      final responseAt1k = coeffs.responseDbAt(1000.0);
      expect(responseAt1k.abs(), lessThan(0.01));
    });

    test('Boosted peaking filter peak magnitude matches gainDb', () {
      final coeffs = AudioEQCookbook.calculate(
        type: FilterType.peaking,
        frequency: 1000.0,
        gainDb: 6.0,
        q: 1.414,
      );

      final responseAt1k = coeffs.responseDbAt(1000.0);
      expect((responseAt1k - 6.0).abs(), lessThan(0.1));
    });

    test('Total response sum with preamp', () {
      final bands = [
        EQBand(id: 'b1', frequency: 1000.0, gainDb: 4.0),
        EQBand(id: 'b2', frequency: 1000.0, gainDb: 2.0),
      ];

      final totalDb = AudioEQCookbook.totalResponseDbAt(
        1000.0,
        bands,
        preampDb: -2.0,
      );

      expect((totalDb - 4.0).abs(), lessThan(0.2));
    });
  });
}
