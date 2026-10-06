import 'dart:math';
import '/models/equalizer_model.dart';

class BiquadCoefficients {
  final double b0;
  final double b1;
  final double b2;
  final double a1;
  final double a2;

  const BiquadCoefficients({
    required this.b0,
    required this.b1,
    required this.b2,
    required this.a1,
    required this.a2,
  });

  /// Computes magnitude response at frequency [f] (Hz) given sampling rate [sampleRate] (Hz).
  /// Returns gain multiplier (linear).
  double responseAt(double f, {double sampleRate = 44100.0}) {
    final w = 2.0 * pi * f / sampleRate;
    final cosW = cos(w);
    final cos2W = cos(2.0 * w);
    final sinW = sin(w);
    final sin2W = sin(2.0 * w);

    final numReal = b0 + b1 * cosW + b2 * cos2W;
    final numImag = -(b1 * sinW + b2 * sin2W);

    final denReal = 1.0 + a1 * cosW + a2 * cos2W;
    final denImag = -(a1 * sinW + a2 * sin2W);

    final numMagSq = numReal * numReal + numImag * numImag;
    final denMagSq = denReal * denReal + denImag * denImag;

    if (denMagSq == 0.0) return 1.0;
    return sqrt(numMagSq / denMagSq);
  }

  /// Computes magnitude response in dB at frequency [f] (Hz).
  double responseDbAt(double f, {double sampleRate = 44100.0}) {
    final mag = responseAt(f, sampleRate: sampleRate);
    if (mag <= 0.0) return -100.0;
    return 20.0 * (log(mag) / ln10);
  }
}

/// Calculates Audio EQ Cookbook biquad filter coefficients.
class AudioEQCookbook {
  static BiquadCoefficients calculate({
    required FilterType type,
    required double frequency,
    required double gainDb,
    required double q,
    double sampleRate = 44100.0,
  }) {
    final f0 = frequency.clamp(10.0, sampleRate / 2.0 - 100.0);
    final A = pow(10.0, gainDb / 40.0).toDouble();
    final w0 = 2.0 * pi * f0 / sampleRate;
    final cosW0 = cos(w0);
    final sinW0 = sin(w0);
    final alpha = sinW0 / (2.0 * max(0.01, q));

    double b0 = 1, b1 = 0, b2 = 0, a0 = 1, a1 = 0, a2 = 0;

    switch (type) {
      case FilterType.peaking:
        b0 = 1.0 + alpha * A;
        b1 = -2.0 * cosW0;
        b2 = 1.0 - alpha * A;
        a0 = 1.0 + alpha / A;
        a1 = -2.0 * cosW0;
        a2 = 1.0 - alpha / A;
        break;

      case FilterType.lowShelf:
        final twoSqrtAAlpha = 2.0 * sqrt(A) * alpha;
        b0 = A * ((A + 1.0) - (A - 1.0) * cosW0 + twoSqrtAAlpha);
        b1 = 2.0 * A * ((A - 1.0) - (A + 1.0) * cosW0);
        b2 = A * ((A + 1.0) - (A - 1.0) * cosW0 - twoSqrtAAlpha);
        a0 = (A + 1.0) + (A - 1.0) * cosW0 + twoSqrtAAlpha;
        a1 = -2.0 * ((A - 1.0) + (A + 1.0) * cosW0);
        a2 = (A + 1.0) + (A - 1.0) * cosW0 - twoSqrtAAlpha;
        break;

      case FilterType.highShelf:
        final twoSqrtAAlpha = 2.0 * sqrt(A) * alpha;
        b0 = A * ((A + 1.0) + (A - 1.0) * cosW0 + twoSqrtAAlpha);
        b1 = -2.0 * A * ((A - 1.0) + (A + 1.0) * cosW0);
        b2 = A * ((A + 1.0) + (A - 1.0) * cosW0 - twoSqrtAAlpha);
        a0 = (A + 1.0) - (A - 1.0) * cosW0 + twoSqrtAAlpha;
        a1 = 2.0 * ((A - 1.0) - (A + 1.0) * cosW0);
        a2 = (A + 1.0) - (A - 1.0) * cosW0 - twoSqrtAAlpha;
        break;

      case FilterType.lowPass:
        b0 = (1.0 - cosW0) / 2.0;
        b1 = 1.0 - cosW0;
        b2 = (1.0 - cosW0) / 2.0;
        a0 = 1.0 + alpha;
        a1 = -2.0 * cosW0;
        a2 = 1.0 - alpha;
        break;

      case FilterType.highPass:
        b0 = (1.0 + cosW0) / 2.0;
        b1 = -(1.0 + cosW0);
        b2 = (1.0 + cosW0) / 2.0;
        a0 = 1.0 + alpha;
        a1 = -2.0 * cosW0;
        a2 = 1.0 - alpha;
        break;

      case FilterType.bandPass:
        b0 = alpha;
        b1 = 0.0;
        b2 = -alpha;
        a0 = 1.0 + alpha;
        a1 = -2.0 * cosW0;
        a2 = 1.0 - alpha;
        break;

      case FilterType.notch:
        b0 = 1.0;
        b1 = -2.0 * cosW0;
        b2 = 1.0;
        a0 = 1.0 + alpha;
        a1 = -2.0 * cosW0;
        a2 = 1.0 - alpha;
        break;
    }

    // Normalize coefficients by a0
    return BiquadCoefficients(
      b0: b0 / a0,
      b1: b1 / a0,
      b2: b2 / a0,
      a1: a1 / a0,
      a2: a2 / a0,
    );
  }

  /// Calculates total magnitude response in dB at [f] Hz for a list of active EQ bands.
  static double totalResponseDbAt(double f, List<EQBand> bands, {double preampDb = 0.0, double sampleRate = 44100.0}) {
    double totalDb = preampDb;
    for (final band in bands) {
      if (!band.enabled) continue;
      final coeffs = calculate(
        type: band.type,
        frequency: band.frequency,
        gainDb: band.gainDb,
        q: band.q,
        sampleRate: sampleRate,
      );
      totalDb += coeffs.responseDbAt(f, sampleRate: sampleRate);
    }
    return totalDb;
  }
}
