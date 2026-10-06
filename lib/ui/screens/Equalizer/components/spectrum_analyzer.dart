import 'dart:math';
import 'package:flutter/material.dart';
import '/models/equalizer_model.dart';
import '/services/biquad_dsp.dart';

enum SpectrumAnalyzerMode {
  spectrum,
  eqCurve,
  spectrumAndCurve;

  String get displayName {
    switch (this) {
      case SpectrumAnalyzerMode.spectrum:
        return 'Spectrum';
      case SpectrumAnalyzerMode.eqCurve:
        return 'EQ Curve';
      case SpectrumAnalyzerMode.spectrumAndCurve:
        return 'Spectrum + Curve';
    }
  }
}

class SpectrumAnalyzerWidget extends StatefulWidget {
  final List<EQBand> bands;
  final double preampDb;
  final SpectrumAnalyzerMode mode;
  final Function(int bandIndex, double newGainDb)? onBandDrag;

  const SpectrumAnalyzerWidget({
    super.key,
    required this.bands,
    this.preampDb = 0.0,
    this.mode = SpectrumAnalyzerMode.spectrumAndCurve,
    this.onBandDrag,
  });

  @override
  State<SpectrumAnalyzerWidget> createState() => _SpectrumAnalyzerWidgetState();
}

class _SpectrumAnalyzerWidgetState extends State<SpectrumAnalyzerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<double> _dummyFft = List.filled(64, 0.0);
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_generateSimulatedFft);
    _animController.repeat();
  }

  void _generateSimulatedFft() {
    if (!mounted) return;
    setState(() {
      for (int i = 0; i < _dummyFft.length; i++) {
        final target = 0.2 + 0.6 * _rnd.nextDouble();
        _dummyFft[i] = _dummyFft[i] * 0.7 + target * 0.3;
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(12),
      child: CustomPaint(
        painter: SpectrumCurvePainter(
          bands: widget.bands,
          preampDb: widget.preampDb,
          mode: widget.mode,
          fftData: _dummyFft,
          accentColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class SpectrumCurvePainter extends CustomPainter {
  final List<EQBand> bands;
  final double preampDb;
  final SpectrumAnalyzerMode mode;
  final List<double> fftData;
  final Color accentColor;

  SpectrumCurvePainter({
    required this.bands,
    required this.preampDb,
    required this.mode,
    required this.fftData,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final centerY = height / 2.0;

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Horizontal dB lines (-15, -10, -5, 0, +5, +10, +15)
    for (double db = -15.0; db <= 15.0; db += 5.0) {
      final y = centerY - (db / 15.0) * (height / 2.2);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // Spectrum Bars
    if (mode == SpectrumAnalyzerMode.spectrum || mode == SpectrumAnalyzerMode.spectrumAndCurve) {
      final barWidth = width / fftData.length;
      final barPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      for (int i = 0; i < fftData.length; i++) {
        final barH = fftData[i] * height * 0.8;
        final x = i * barWidth;
        final y = height - barH;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 1, y, barWidth - 2, barH),
            const Radius.circular(2),
          ),
          barPaint,
        );
      }
    }

    // EQ Curve
    if (mode == SpectrumAnalyzerMode.eqCurve || mode == SpectrumAnalyzerMode.spectrumAndCurve) {
      final path = Path();
      final points = <Offset>[];

      for (double x = 0; x <= width; x += 2.0) {
        // Map x position linearly to logarithmic frequency (20 Hz - 20,000 Hz)
        final freq = 20.0 * pow(1000.0, x / width);
        final db = AudioEQCookbook.totalResponseDbAt(freq, bands, preampDb: preampDb);
        final y = (centerY - (db / 15.0) * (height / 2.2)).clamp(0.0, height);

        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        points.add(Offset(x, y));
      }

      final curvePaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, curvePaint);

      // Draw active band control points
      final pointPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final pointOuterPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill;

      for (var band in bands) {
        if (!band.enabled) continue;
        final normX = log(band.frequency / 20.0) / log(1000.0);
        final x = (normX * width).clamp(0.0, width);
        final db = AudioEQCookbook.totalResponseDbAt(band.frequency, bands, preampDb: preampDb);
        final y = (centerY - (db / 15.0) * (height / 2.2)).clamp(0.0, height);

        canvas.drawCircle(Offset(x, y), 6, pointOuterPaint);
        canvas.drawCircle(Offset(x, y), 3, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SpectrumCurvePainter oldDelegate) => true;
}
