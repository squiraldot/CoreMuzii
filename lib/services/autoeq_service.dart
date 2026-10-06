import '/models/equalizer_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AutoEQProfile {
  final String modelName;
  final String brand;
  final List<EQBand> recommendedBands;
  final double preampDb;

  AutoEQProfile({
    required this.modelName,
    required this.brand,
    required this.recommendedBands,
    this.preampDb = -3.0,
  });

  EQPreset toPreset() {
    return EQPreset(
      id: 'autoeq_${brand.toLowerCase()}_${modelName.toLowerCase().replaceAll(' ', '_')}',
      name: '$brand $modelName (AutoEQ)',
      author: 'AutoEQ Database',
      description: 'Harman target compensated AutoEQ profile for $brand $modelName',
      isBuiltIn: false,
      preampDb: preampDb,
      bands: recommendedBands,
      isParametric: true,
    );
  }
}

class AutoEQService {
  static final List<AutoEQProfile> _builtinProfiles = [
    AutoEQProfile(
      brand: 'Sony',
      modelName: 'WH-1000XM4',
      preampDb: -4.5,
      recommendedBands: [
        EQBand(id: 'a1', type: FilterType.peaking, frequency: 31, gainDb: -1.2, q: 1.41),
        EQBand(id: 'a2', type: FilterType.peaking, frequency: 62, gainDb: -3.5, q: 1.0),
        EQBand(id: 'a3', type: FilterType.peaking, frequency: 125, gainDb: -4.0, q: 1.2),
        EQBand(id: 'a4', type: FilterType.peaking, frequency: 250, gainDb: -2.0, q: 1.41),
        EQBand(id: 'a5', type: FilterType.peaking, frequency: 500, gainDb: 0.5, q: 1.41),
        EQBand(id: 'a6', type: FilterType.peaking, frequency: 1000, gainDb: 2.0, q: 1.41),
        EQBand(id: 'a7', type: FilterType.peaking, frequency: 2000, gainDb: 1.5, q: 1.41),
        EQBand(id: 'a8', type: FilterType.peaking, frequency: 4000, gainDb: 3.2, q: 1.41),
        EQBand(id: 'a9', type: FilterType.peaking, frequency: 8000, gainDb: -1.5, q: 1.41),
        EQBand(id: 'a10', type: FilterType.peaking, frequency: 16000, gainDb: 1.0, q: 1.41),
      ],
    ),
    AutoEQProfile(
      brand: 'Sennheiser',
      modelName: 'HD 600',
      preampDb: -3.0,
      recommendedBands: [
        EQBand(id: 'a1', type: FilterType.peaking, frequency: 31, gainDb: 4.5, q: 1.0),
        EQBand(id: 'a2', type: FilterType.peaking, frequency: 62, gainDb: 3.0, q: 1.2),
        EQBand(id: 'a3', type: FilterType.peaking, frequency: 125, gainDb: 1.0, q: 1.41),
        EQBand(id: 'a4', type: FilterType.peaking, frequency: 250, gainDb: 0.0, q: 1.41),
        EQBand(id: 'a5', type: FilterType.peaking, frequency: 500, gainDb: 0.0, q: 1.41),
        EQBand(id: 'a6', type: FilterType.peaking, frequency: 1000, gainDb: 0.0, q: 1.41),
        EQBand(id: 'a7', type: FilterType.peaking, frequency: 2000, gainDb: -1.0, q: 1.41),
        EQBand(id: 'a8', type: FilterType.peaking, frequency: 4000, gainDb: 1.5, q: 1.41),
        EQBand(id: 'a9', type: FilterType.peaking, frequency: 8000, gainDb: -2.0, q: 1.41),
        EQBand(id: 'a10', type: FilterType.peaking, frequency: 16000, gainDb: 0.5, q: 1.41),
      ],
    ),
    AutoEQProfile(
      brand: 'Apple',
      modelName: 'AirPods Pro 2',
      preampDb: -2.0,
      recommendedBands: [
        EQBand(id: 'a1', type: FilterType.peaking, frequency: 31, gainDb: 1.5, q: 1.41),
        EQBand(id: 'a2', type: FilterType.peaking, frequency: 62, gainDb: 1.0, q: 1.41),
        EQBand(id: 'a3', type: FilterType.peaking, frequency: 125, gainDb: 0.0, q: 1.41),
        EQBand(id: 'a4', type: FilterType.peaking, frequency: 250, gainDb: -0.5, q: 1.41),
        EQBand(id: 'a5', type: FilterType.peaking, frequency: 500, gainDb: 0.0, q: 1.41),
        EQBand(id: 'a6', type: FilterType.peaking, frequency: 1000, gainDb: 0.5, q: 1.41),
        EQBand(id: 'a7', type: FilterType.peaking, frequency: 2000, gainDb: 2.0, q: 1.41),
        EQBand(id: 'a8', type: FilterType.peaking, frequency: 4000, gainDb: -1.0, q: 1.41),
        EQBand(id: 'a9', type: FilterType.peaking, frequency: 8000, gainDb: 1.5, q: 1.41),
        EQBand(id: 'a10', type: FilterType.peaking, frequency: 16000, gainDb: 0.0, q: 1.41),
      ],
    ),
  ];

  static List<AutoEQProfile> searchHeadphones(String query) {
    if (query.trim().isEmpty) return _builtinProfiles;
    final q = query.toLowerCase().trim();
    return _builtinProfiles.where((p) {
      final full = '${p.brand} ${p.modelName}'.toLowerCase();
      return full.contains(q);
    }).toList();
  }

  /// Shares a preset via system share sheet / Telegram.
  static Future<void> sharePresetToTelegram(EQPreset preset) async {
    final jsonStr = preset.toMdleqString();
    final text = 'Check out my MDLovFi Equalizer preset "${preset.name}"!\n\n```json\n$jsonStr\n```';

    final tgUri = Uri.parse('https://t.me/share/url?url=${Uri.encodeComponent('https://github.com/squiraldot/CoreMuzii')}&text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(tgUri)) {
      await launchUrl(tgUri, mode: LaunchMode.externalApplication);
    } else {
      await Share.share(text, subject: 'MDLovFi Preset - ${preset.name}');
    }
  }
}
