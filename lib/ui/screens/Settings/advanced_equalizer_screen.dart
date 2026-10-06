import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/models/equalizer.dart';
import '/services/constant.dart';
import '/ui/player/player_controller.dart';

class AdvancedEqualizerScreen extends StatefulWidget {
  const AdvancedEqualizerScreen({super.key});

  @override
  State<AdvancedEqualizerScreen> createState() =>
      _AdvancedEqualizerScreenState();
}

class _AdvancedEqualizerScreenState extends State<AdvancedEqualizerScreen> {
  late EqualizerConfig _config;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _config = _loadConfig();
  }

  EqualizerConfig _loadConfig() {
    final saved = Hive.box(appPrefsBoxName).get('equalizerConfig');
    if (saved is String) {
      try {
        return EqualizerConfig.fromJson(
          Map<String, Object?>.from(jsonDecode(saved) as Map),
        );
      } catch (_) {}
    }
    return EqualizerConfig.graphic10Band();
  }

  Future<void> _commit(EqualizerConfig config) async {
    setState(() {
      _config = config;
      _saving = true;
    });
    try {
      await Get.find<PlayerController>().setEqualizerConfig(config);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _setBandGain(int index, double gainDb) {
    final bands = List<EqualizerBand>.from(_config.bands);
    bands[index] = bands[index].copyWith(gainDb: gainDb);
    setState(() => _config = _config.copyWith(bands: bands));
  }

  void _setBandGainFromGraph(Offset position, Size size) {
    if (_config.bands.isEmpty || size.width <= 0 || size.height <= 0) return;
    final x = (position.dx / size.width).clamp(0.0, 1.0);
    final y = (position.dy / size.height).clamp(0.0, 1.0);
    final index = (x * (_config.bands.length - 1)).round();
    final gain = (15 - y * 30).clamp(-15.0, 15.0);
    _setBandGain(index, gain);
  }

  @override
  Widget build(BuildContext context) {
    final frequencies =
        _config.bands.map((band) => band.frequency.round()).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Equalizer'),
        actions: [
          IconButton(
            tooltip: 'Reset',
            onPressed: _saving
                ? null
                : () => _commit(EqualizerConfig.graphic10Band()),
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '10-Band Graphic',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              Switch(
                value: _config.enabled,
                onChanged: (value) =>
                    _commit(_config.copyWith(enabled: value)),
              ),
            ],
          ),
          Text(
            'Changes are applied to the current playback session.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, 190);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) =>
                    _setBandGainFromGraph(details.localPosition, size),
                onPanEnd: (_) => _commit(_config),
                child: SizedBox(
                  height: size.height,
                  width: size.width,
                  child: CustomPaint(
                    painter: _EqualizerCurvePainter(
                      bands: _config.bands,
                      textStyle: Theme.of(context).textTheme.bodySmall!,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text('Preamp'),
              const Spacer(),
              Text(_config.preampDb.toStringAsFixed(1) + ' dB'),
            ],
          ),
          Slider(
            min: -15,
            max: 15,
            value: _config.preampDb,
            onChanged: (value) => setState(
              () => _config = _config.copyWith(preampDb: value),
            ),
            onChangeEnd: (value) =>
                _commit(_config.copyWith(preampDb: value)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bands',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < _config.bands.length; i++)
            _BandSlider(
              frequency: frequencies[i],
              gainDb: _config.bands[i].gainDb,
              enabled: _config.enabled,
              onChanged: (value) => _setBandGain(i, value),
              onChangeEnd: (value) => _commit(
                _config.copyWith(
                  bands: [
                    for (var j = 0; j < _config.bands.length; j++)
                      j == i
                          ? _config.bands[j].copyWith(gainDb: value)
                          : _config.bands[j],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Limiter'),
            subtitle:
                const Text('Protects against clipping when boosting bands.'),
            value: _config.limiterEnabled,
            onChanged: _config.enabled
                ? (value) =>
                    _commit(_config.copyWith(limiterEnabled: value))
                : null,
          ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class _BandSlider extends StatelessWidget {
  const _BandSlider({
    required this.frequency,
    required this.gainDb,
    required this.enabled,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final int frequency;
  final double gainDb;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            frequency >= 1000
                ? (frequency ~/ 1000).toString() + 'k'
                : frequency.toString(),
            textAlign: TextAlign.end,
          ),
        ),
        Expanded(
          child: Slider(
            min: -15,
            max: 15,
            value: gainDb,
            onChanged: enabled ? onChanged : null,
            onChangeEnd: enabled ? onChangeEnd : null,
          ),
        ),
        SizedBox(
          width: 54,
          child: Text(
            gainDb.toStringAsFixed(1) + ' dB',
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _EqualizerCurvePainter extends CustomPainter {
  const _EqualizerCurvePainter({
    required this.bands,
    required this.textStyle,
  });

  final List<EqualizerBand> bands;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final curvePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final dotPaint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i <= 6; i++) {
      final y = size.height * i / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (var i = 0; i < bands.length; i++) {
      final x = bands.length == 1
          ? size.width / 2
          : size.width * i / (bands.length - 1);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final path = Path();
    for (var i = 0; i < bands.length; i++) {
      final x = bands.length == 1
          ? size.width / 2
          : size.width * i / (bands.length - 1);
      final y =
          ((15 - bands[i].gainDb) / 30).clamp(0.0, 1.0) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 5, dotPaint);
    }

    canvas.drawPath(path, curvePaint);

    final zeroY = size.height / 2;
    final zeroPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), zeroPaint);
  }

  @override
  bool shouldRepaint(covariant _EqualizerCurvePainter oldDelegate) {
    return oldDelegate.bands != bands;
  }
}
