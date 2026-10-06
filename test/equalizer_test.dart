import 'package:flutter_test/flutter_test.dart';
import 'package:mdlovfimusic/models/equalizer.dart';
import 'package:mdlovfimusic/services/equalizer/biquad.dart';

void main() {
  group('EqualizerBand', () {
    test('serializes all DSP fields without losing precision', () {
      final band = EqualizerBand(
        id: 'band-1',
        type: EqualizerFilterType.peaking,
        frequency: 1000,
        gainDb: 4.5,
        q: 1.2,
        enabled: true,
      );

      expect(EqualizerBand.fromJson(band.toJson()), equals(band));
    });

    test('rejects unsafe gain and frequency values', () {
      expect(
        () => EqualizerBand(
          id: 'bad',
          type: EqualizerFilterType.peaking,
          frequency: 10,
          gainDb: 20,
          q: 1,
          enabled: true,
        ),
        throwsArgumentError,
      );
    });
  });

  group('EqualizerConfig', () {
    test('creates the canonical ten-band graphic layout', () {
      final config = EqualizerConfig.graphic10Band();

      expect(config.bands, hasLength(10));
      expect(
        config.bands.map((band) => band.frequency).toList(),
        [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000],
      );
      expect(config.bands.every((band) => band.gainDb == 0), isTrue);
    });

    test('uses the stable v1 portable EQ schema', () {
      final json = EqualizerConfig.graphic10Band().toJson();

      expect(json['format'], 'mdlovfi-eq');
      expect(json['version'], 1);
      expect(json['enabled'], isTrue);
      expect(json['limiterEnabled'], isTrue);
    });

    test('round-trips the complete config format', () {
      final config = EqualizerConfig.graphic10Band().copyWith(
        enabled: false,
        preampDb: -3.5,
        outputGainDb: 2,
        limiterEnabled: false,
      );

      expect(
        EqualizerConfig.fromJson(config.toJson()),
        equals(config),
      );
    });

    test('clamps preamp and output gain to the safe range', () {
      final config = EqualizerConfig(
        preampDb: 99,
        outputGainDb: -99,
        bands: const [],
      );

      expect(config.preampDb, 15);
      expect(config.outputGainDb, -15);
    });
  });

  group('BiquadCalculator', () {
    test('zero-gain peaking filter is transparent', () {
      final coefficients = BiquadCalculator.peaking(
        sampleRate: 48000,
        frequency: 1000,
        gainDb: 0,
        q: 1,
      );

      expect(coefficients.b0, closeTo(1, 1e-12));
      expect(coefficients.b1, closeTo(coefficients.a1, 1e-12));
      expect(coefficients.b2, closeTo(coefficients.a2, 1e-12));
    });

    test('rejects a band at or above Nyquist', () {
      expect(
        () => BiquadCalculator.peaking(
          sampleRate: 48000,
          frequency: 24000,
          gainDb: 3,
          q: 1,
        ),
        throwsArgumentError,
      );
    });
  });
}
