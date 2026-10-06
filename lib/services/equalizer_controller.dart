import 'dart:convert';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '/models/equalizer_model.dart';
import '/services/constant.dart';
import '/services/equalizer.dart';

class EqualizerController extends GetxController {
  int _audioSessionId = 0;

  void setAudioSessionId(int id) {
    _audioSessionId = id;
    applyCurrentEqToNativeHardware();
  }

  void applyCurrentEqToNativeHardware() {
    if (_audioSessionId <= 0) return;

    if (!isEnabled.value) {
      EqualizerService.setBandGains(_audioSessionId, List.filled(10, 0));
      EqualizerService.setBassBoost(_audioSessionId, 0);
      EqualizerService.setLoudnessGain(_audioSessionId, 0);
      return;
    }

    // Convert band gains from dB to millibels (1 dB = 100 mB)
    final mbGains = activeBands.map((b) => (b.gainDb * 100).toInt()).toList();
    EqualizerService.setBandGains(_audioSessionId, mbGains);

    if (dspSettings.value.bassBoostEnabled) {
      final strength = (dspSettings.value.bassBoostAmount * 10).toInt(); // 0 to 1000
      EqualizerService.setBassBoost(_audioSessionId, strength);
    } else {
      EqualizerService.setBassBoost(_audioSessionId, 0);
    }

    if (dspSettings.value.loudnessEnabled) {
      final gainMb = (dspSettings.value.loudnessGainDb * 100).toInt();
      EqualizerService.setLoudnessGain(_audioSessionId, gainMb);
    } else {
      EqualizerService.setLoudnessGain(_audioSessionId, 0);
    }
  }
  static const String customPresetsKey = 'custom_eq_presets';
  static const String activePresetIdKey = 'active_eq_preset_id';
  static const String currentEqStateKey = 'current_eq_state';

  final RxBool isEnabled = true.obs;
  final RxDouble preampDb = 0.0.obs;
  final RxBool isParametricMode = false.obs;

  final RxList<EQBand> graphicBands = <EQBand>[].obs;
  final RxList<EQBand> parametricBands = <EQBand>[].obs;
  final Rx<DSPSettings> dspSettings = DSPSettings().obs;

  final RxList<EQPreset> builtInPresets = <EQPreset>[].obs;
  final RxList<EQPreset> customPresets = <EQPreset>[].obs;
  final Rx<EQPreset?> currentPreset = Rx<EQPreset?>(null);

  static const List<double> defaultGraphicFrequencies = [
    31.0,
    62.0,
    125.0,
    250.0,
    500.0,
    1000.0,
    2000.0,
    4000.0,
    8000.0,
    16000.0,
  ];

  @override
  void onInit() {
    super.onInit();
    _initBuiltInPresets();
    _initGraphicBands();
    _initParametricBands();
    loadPresetsFromHive();
  }

  void _initGraphicBands() {
    graphicBands.assignAll(
      defaultGraphicFrequencies
          .map((freq) => EQBand(
                id: 'graphic_${freq.toInt()}',
                type: FilterType.peaking,
                frequency: freq,
                gainDb: 0.0,
                q: 1.414,
                enabled: true,
              ))
          .toList(),
    );
  }

  void _initParametricBands() {
    parametricBands.assignAll([
      EQBand(id: 'p_1', type: FilterType.lowShelf, frequency: 80.0, gainDb: 0.0, q: 0.707),
      EQBand(id: 'p_2', type: FilterType.peaking, frequency: 250.0, gainDb: 0.0, q: 1.414),
      EQBand(id: 'p_3', type: FilterType.peaking, frequency: 1000.0, gainDb: 0.0, q: 1.414),
      EQBand(id: 'p_4', type: FilterType.peaking, frequency: 4000.0, gainDb: 0.0, q: 1.414),
      EQBand(id: 'p_5', type: FilterType.highShelf, frequency: 12000.0, gainDb: 0.0, q: 0.707),
    ]);
  }

  void _initBuiltInPresets() {
    List<EQBand> makeBands(List<double> gains) {
      assert(gains.length == defaultGraphicFrequencies.length);
      return List.generate(
        gains.length,
        (i) => EQBand(
          id: 'b_${defaultGraphicFrequencies[i].toInt()}',
          type: FilterType.peaking,
          frequency: defaultGraphicFrequencies[i],
          gainDb: gains[i],
          q: 1.414,
        ),
      );
    }

    builtInPresets.assignAll([
      EQPreset(
        id: 'builtin_flat',
        name: 'Flat',
        isBuiltIn: true,
        bands: makeBands([0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
      ),
      EQPreset(
        id: 'builtin_bass_boost',
        name: 'Bass Boost',
        isBuiltIn: true,
        preampDb: -3.0,
        bands: makeBands([6, 5, 4, 2, 0, 0, 0, 0, 0, 0]),
      ),
      EQPreset(
        id: 'builtin_deep_bass',
        name: 'Deep Bass',
        isBuiltIn: true,
        preampDb: -4.0,
        bands: makeBands([8, 7, 5, 2, -1, -1, 0, 0, 0, 0]),
      ),
      EQPreset(
        id: 'builtin_vocal',
        name: 'Vocal',
        isBuiltIn: true,
        preampDb: -2.0,
        bands: makeBands([-2, -1, 1, 3, 4, 4, 3, 1, 0, -1]),
      ),
      EQPreset(
        id: 'builtin_pop',
        name: 'Pop',
        isBuiltIn: true,
        preampDb: -2.0,
        bands: makeBands([-1, 1, 2, 3, 2, 0, -1, -1, 1, 2]),
      ),
      EQPreset(
        id: 'builtin_rock',
        name: 'Rock',
        isBuiltIn: true,
        preampDb: -3.0,
        bands: makeBands([5, 4, 2, 0, -1, 0, 2, 3, 4, 4]),
      ),
      EQPreset(
        id: 'builtin_jazz',
        name: 'Jazz',
        isBuiltIn: true,
        preampDb: -2.0,
        bands: makeBands([3, 2, 0, 2, -1, -1, 0, 1, 2, 3]),
      ),
      EQPreset(
        id: 'builtin_classical',
        name: 'Classical',
        isBuiltIn: true,
        preampDb: -2.0,
        bands: makeBands([4, 3, 2, 2, -1, -1, 0, 2, 3, 4]),
      ),
      EQPreset(
        id: 'builtin_acoustic',
        name: 'Acoustic',
        isBuiltIn: true,
        preampDb: -2.0,
        bands: makeBands([3, 2, 1, 1, 2, 1, 2, 3, 3, 2]),
      ),
      EQPreset(
        id: 'builtin_edm',
        name: 'EDM',
        isBuiltIn: true,
        preampDb: -3.5,
        bands: makeBands([6, 5, 3, 0, -2, 1, 2, 3, 4, 5]),
      ),
      EQPreset(
        id: 'builtin_hiphop',
        name: 'Hip-Hop',
        isBuiltIn: true,
        preampDb: -3.0,
        bands: makeBands([6, 5, 2, 1, -1, -1, 1, 0, 2, 3]),
      ),
      EQPreset(
        id: 'builtin_metal',
        name: 'Metal',
        isBuiltIn: true,
        preampDb: -3.0,
        bands: makeBands([4, 3, 1, -2, -1, 1, 3, 4, 4, 3]),
      ),
      EQPreset(
        id: 'builtin_podcast',
        name: 'Podcast',
        isBuiltIn: true,
        preampDb: -1.0,
        bands: makeBands([-4, -2, 0, 2, 4, 3, 2, 0, -2, -4]),
      ),
      EQPreset(
        id: 'builtin_warm',
        name: 'Warm',
        isBuiltIn: true,
        preampDb: -2.0,
        bands: makeBands([3, 3, 2, 2, 1, 0, -1, -2, -2, -3]),
      ),
      EQPreset(
        id: 'builtin_bright',
        name: 'Bright',
        isBuiltIn: true,
        preampDb: -2.0,
        bands: makeBands([-3, -2, -1, 0, 1, 2, 3, 4, 4, 5]),
      ),
      EQPreset(
        id: 'builtin_night',
        name: 'Night',
        isBuiltIn: true,
        preampDb: -1.0,
        bands: makeBands([1, 1, 0, 0, 0, -1, -2, -3, -4, -5]),
      ),
      EQPreset(
        id: 'builtin_cinematic',
        name: 'Cinematic',
        isBuiltIn: true,
        preampDb: -3.0,
        bands: makeBands([5, 4, 2, 0, -1, 0, 1, 2, 4, 4]),
      ),
      EQPreset(
        id: 'builtin_loud',
        name: 'Loud',
        isBuiltIn: true,
        preampDb: -4.0,
        bands: makeBands([6, 4, 2, 0, -1, 0, 2, 0, 4, 2]),
      ),
    ]);
  }

  void loadPresetsFromHive() {
    try {
      final box = Hive.box(appPrefsBoxName);
      final String? customPresetsJson = box.get(customPresetsKey);
      if (customPresetsJson != null) {
        final List<dynamic> decoded = jsonDecode(customPresetsJson);
        customPresets.assignAll(
          decoded.map((item) => EQPreset.fromJson(item as Map<String, dynamic>)).toList(),
        );
      }

      final String? currentStateJson = box.get(currentEqStateKey);
      if (currentStateJson != null) {
        final Map<String, dynamic> stateMap = jsonDecode(currentStateJson);
        isEnabled.value = stateMap['enabled'] as bool? ?? true;
        preampDb.value = (stateMap['preampDb'] as num?)?.toDouble() ?? 0.0;
        isParametricMode.value = stateMap['isParametricMode'] as bool? ?? false;
        if (stateMap['graphicBands'] != null) {
          graphicBands.assignAll(
            (stateMap['graphicBands'] as List<dynamic>)
                .map((b) => EQBand.fromJson(b as Map<String, dynamic>))
                .toList(),
          );
        }
        if (stateMap['parametricBands'] != null) {
          parametricBands.assignAll(
            (stateMap['parametricBands'] as List<dynamic>)
                .map((b) => EQBand.fromJson(b as Map<String, dynamic>))
                .toList(),
          );
        }
        if (stateMap['dsp'] != null) {
          dspSettings.value = DSPSettings.fromJson(stateMap['dsp'] as Map<String, dynamic>);
        }
      }

      final String? activeId = box.get(activePresetIdKey);
      if (activeId != null) {
        final preset = allPresets.firstWhereOrNull((p) => p.id == activeId);
        if (preset != null) {
          currentPreset.value = preset;
        }
      } else {
        currentPreset.value = builtInPresets.first;
      }
    } catch (e) {
      print('Error loading EQ state from Hive: $e');
    }
  }

  void saveStateToHive() {
    try {
      final box = Hive.box(appPrefsBoxName);
      final customJson = jsonEncode(customPresets.map((p) => p.toJson()).toList());
      box.put(customPresetsKey, customJson);

      final currentStateMap = {
        'enabled': isEnabled.value,
        'preampDb': preampDb.value,
        'isParametricMode': isParametricMode.value,
        'graphicBands': graphicBands.map((b) => b.toJson()).toList(),
        'parametricBands': parametricBands.map((b) => b.toJson()).toList(),
        'dsp': dspSettings.value.toJson(),
      };
      box.put(currentEqStateKey, jsonEncode(currentStateMap));
      if (currentPreset.value != null) {
        box.put(activePresetIdKey, currentPreset.value!.id);
      }
      applyCurrentEqToNativeHardware();
    } catch (e) {
      print('Error saving EQ state to Hive: $e');
    }
  }

  List<EQPreset> get allPresets => [...builtInPresets, ...customPresets];

  List<EQBand> get activeBands => isParametricMode.value ? parametricBands : graphicBands;

  void toggleEnabled() {
    isEnabled.value = !isEnabled.value;
    saveStateToHive();
  }

  void setPreamp(double val) {
    preampDb.value = val.clamp(-15.0, 15.0);
    saveStateToHive();
  }

  void updateBandGain(int index, double gainDb) {
    final list = isParametricMode.value ? parametricBands : graphicBands;
    if (index >= 0 && index < list.length) {
      list[index] = list[index].copyWith(gainDb: gainDb.clamp(-15.0, 15.0));
      saveStateToHive();
    }
  }

  void resetFlat() {
    for (int i = 0; i < graphicBands.length; i++) {
      graphicBands[i] = graphicBands[i].copyWith(gainDb: 0.0);
    }
    preampDb.value = 0.0;
    currentPreset.value = builtInPresets.firstWhere((p) => p.id == 'builtin_flat');
    saveStateToHive();
  }

  void applyPreset(EQPreset preset) {
    currentPreset.value = preset;
    preampDb.value = preset.preampDb;
    isParametricMode.value = preset.isParametric;

    if (preset.isParametric) {
      parametricBands.assignAll(preset.bands.map((b) => b.copyWith()).toList());
    } else {
      for (var b in preset.bands) {
        final idx = graphicBands.indexWhere((gb) => (gb.frequency - b.frequency).abs() < 5.0);
        if (idx != -1) {
          graphicBands[idx] = graphicBands[idx].copyWith(gainDb: b.gainDb, enabled: b.enabled);
        }
      }
    }
    dspSettings.value = preset.dsp.copyWith();
    saveStateToHive();
  }

  EQPreset saveCustomPreset(String name, {String author = 'User', String description = ''}) {
    final newPreset = EQPreset(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      author: author,
      description: description,
      isBuiltIn: false,
      enabled: isEnabled.value,
      preampDb: preampDb.value,
      bands: activeBands.map((b) => b.copyWith()).toList(),
      dsp: dspSettings.value.copyWith(),
      isParametric: isParametricMode.value,
    );

    customPresets.add(newPreset);
    currentPreset.value = newPreset;
    saveStateToHive();
    return newPreset;
  }

  bool deleteCustomPreset(String id) {
    final idx = customPresets.indexWhere((p) => p.id == id);
    if (idx != -1) {
      customPresets.removeAt(idx);
      if (currentPreset.value?.id == id) {
        applyPreset(builtInPresets.first);
      } else {
        saveStateToHive();
      }
      return true;
    }
    return false;
  }

  /// Parses and validates a .mdleq JSON string. Returns the imported EQPreset or throws FormatException.
  EQPreset parseMdleqJson(String jsonStr) {
    final dynamic decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid JSON payload for .mdleq file');
    }
    final preset = EQPreset.fromMdleqJson(decoded);
    // Sanitize band gains and frequencies for safe audio application
    for (var b in preset.bands) {
      b.gainDb = b.gainDb.clamp(-20.0, 20.0);
      b.q = b.q.clamp(0.1, 10.0);
    }
    preset.preampDb = preset.preampDb.clamp(-20.0, 20.0);
    return preset;
  }

  /// Imports an EQPreset into custom presets list and applies it if requested.
  EQPreset importPreset(EQPreset preset, {bool applyImmediately = true}) {
    customPresets.add(preset);
    if (applyImmediately) {
      applyPreset(preset);
    } else {
      saveStateToHive();
    }
    return preset;
  }

  /// Generates printable/exportable .mdleq JSON string for the given preset or current active state.
  String exportPresetToMdleqString({EQPreset? preset}) {
    final targetPreset = preset ??
        EQPreset(
          id: 'export_${DateTime.now().millisecondsSinceEpoch}',
          name: currentPreset.value?.name ?? 'Custom EQ',
          author: 'MDLovFi User',
          description: 'Exported from MDLovFi',
          enabled: isEnabled.value,
          preampDb: preampDb.value,
          bands: activeBands.map((b) => b.copyWith()).toList(),
          dsp: dspSettings.value.copyWith(),
          isParametric: isParametricMode.value,
        );

    return targetPreset.toMdleqString();
  }
}
