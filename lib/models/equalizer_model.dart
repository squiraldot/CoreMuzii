import 'dart:convert';

enum FilterType {
  peaking,
  lowShelf,
  highShelf,
  lowPass,
  highPass,
  bandPass,
  notch;

  String get displayName {
    switch (this) {
      case FilterType.peaking:
        return 'Peaking';
      case FilterType.lowShelf:
        return 'Low Shelf';
      case FilterType.highShelf:
        return 'High Shelf';
      case FilterType.lowPass:
        return 'Low Pass';
      case FilterType.highPass:
        return 'High Pass';
      case FilterType.bandPass:
        return 'Band Pass';
      case FilterType.notch:
        return 'Notch';
    }
  }

  static FilterType fromString(String name) {
    return FilterType.values.firstWhere(
      (e) => e.name.toLowerCase() == name.toLowerCase() || e.displayName.toLowerCase() == name.toLowerCase(),
      orElse: () => FilterType.peaking,
    );
  }
}

class EQBand {
  final String id;
  final FilterType type;
  final double frequency; // Hz
  double gainDb; // dB (-15 to +15)
  double q; // Q factor
  bool enabled;

  EQBand({
    required this.id,
    this.type = FilterType.peaking,
    required this.frequency,
    this.gainDb = 0.0,
    this.q = 1.414,
    this.enabled = true,
  });

  EQBand copyWith({
    String? id,
    FilterType? type,
    double? frequency,
    double? gainDb,
    double? q,
    bool? enabled,
  }) {
    return EQBand(
      id: id ?? this.id,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      gainDb: gainDb ?? this.gainDb,
      q: q ?? this.q,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'frequency': frequency,
      'gainDb': gainDb,
      'q': q,
      'enabled': enabled,
    };
  }

  factory EQBand.fromJson(Map<String, dynamic> json) {
    return EQBand(
      id: json['id'] as String? ?? 'band_${json['frequency']}',
      type: FilterType.fromString(json['type'] as String? ?? 'peaking'),
      frequency: (json['frequency'] as num?)?.toDouble() ?? 1000.0,
      gainDb: (json['gainDb'] as num?)?.toDouble() ?? 0.0,
      q: (json['q'] as num?)?.toDouble() ?? 1.414,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

class DSPSettings {
  bool limiterEnabled;
  double limiterCeilingDb;
  double limiterReleaseMs;

  bool bassBoostEnabled;
  double bassBoostAmount; // 0.0 - 100.0 %
  double bassBoostFreq; // Hz

  bool loudnessEnabled;
  double loudnessGainDb;

  bool compressorEnabled;
  double compressorThresholdDb;
  double compressorRatio;
  double compressorAttackMs;
  double compressorReleaseMs;
  double compressorMakeupGainDb;

  bool stereoWidthEnabled;
  double stereoWidth; // 0.0 - 2.0 (1.0 = normal)

  DSPSettings({
    this.limiterEnabled = true,
    this.limiterCeilingDb = -0.1,
    this.limiterReleaseMs = 100.0,
    this.bassBoostEnabled = false,
    this.bassBoostAmount = 0.0,
    this.bassBoostFreq = 80.0,
    this.loudnessEnabled = false,
    this.loudnessGainDb = 0.0,
    this.compressorEnabled = false,
    this.compressorThresholdDb = -12.0,
    this.compressorRatio = 2.0,
    this.compressorAttackMs = 10.0,
    this.compressorReleaseMs = 100.0,
    this.compressorMakeupGainDb = 0.0,
    this.stereoWidthEnabled = false,
    this.stereoWidth = 1.0,
  });

  DSPSettings copyWith({
    bool? limiterEnabled,
    double? limiterCeilingDb,
    double? limiterReleaseMs,
    bool? bassBoostEnabled,
    double? bassBoostAmount,
    double? bassBoostFreq,
    bool? loudnessEnabled,
    double? loudnessGainDb,
    bool? compressorEnabled,
    double? compressorThresholdDb,
    double? compressorRatio,
    double? compressorAttackMs,
    double? compressorReleaseMs,
    double? compressorMakeupGainDb,
    bool? stereoWidthEnabled,
    double? stereoWidth,
  }) {
    return DSPSettings(
      limiterEnabled: limiterEnabled ?? this.limiterEnabled,
      limiterCeilingDb: limiterCeilingDb ?? this.limiterCeilingDb,
      limiterReleaseMs: limiterReleaseMs ?? this.limiterReleaseMs,
      bassBoostEnabled: bassBoostEnabled ?? this.bassBoostEnabled,
      bassBoostAmount: bassBoostAmount ?? this.bassBoostAmount,
      bassBoostFreq: bassBoostFreq ?? this.bassBoostFreq,
      loudnessEnabled: loudnessEnabled ?? this.loudnessEnabled,
      loudnessGainDb: loudnessGainDb ?? this.loudnessGainDb,
      compressorEnabled: compressorEnabled ?? this.compressorEnabled,
      compressorThresholdDb: compressorThresholdDb ?? this.compressorThresholdDb,
      compressorRatio: compressorRatio ?? this.compressorRatio,
      compressorAttackMs: compressorAttackMs ?? this.compressorAttackMs,
      compressorReleaseMs: compressorReleaseMs ?? this.compressorReleaseMs,
      compressorMakeupGainDb: compressorMakeupGainDb ?? this.compressorMakeupGainDb,
      stereoWidthEnabled: stereoWidthEnabled ?? this.stereoWidthEnabled,
      stereoWidth: stereoWidth ?? this.stereoWidth,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'limiterEnabled': limiterEnabled,
      'limiterCeilingDb': limiterCeilingDb,
      'limiterReleaseMs': limiterReleaseMs,
      'bassBoostEnabled': bassBoostEnabled,
      'bassBoostAmount': bassBoostAmount,
      'bassBoostFreq': bassBoostFreq,
      'loudnessEnabled': loudnessEnabled,
      'loudnessGainDb': loudnessGainDb,
      'compressorEnabled': compressorEnabled,
      'compressorThresholdDb': compressorThresholdDb,
      'compressorRatio': compressorRatio,
      'compressorAttackMs': compressorAttackMs,
      'compressorReleaseMs': compressorReleaseMs,
      'compressorMakeupGainDb': compressorMakeupGainDb,
      'stereoWidthEnabled': stereoWidthEnabled,
      'stereoWidth': stereoWidth,
    };
  }

  factory DSPSettings.fromJson(Map<String, dynamic> json) {
    return DSPSettings(
      limiterEnabled: json['limiterEnabled'] as bool? ?? true,
      limiterCeilingDb: (json['limiterCeilingDb'] as num?)?.toDouble() ?? -0.1,
      limiterReleaseMs: (json['limiterReleaseMs'] as num?)?.toDouble() ?? 100.0,
      bassBoostEnabled: json['bassBoostEnabled'] as bool? ?? false,
      bassBoostAmount: (json['bassBoostAmount'] as num?)?.toDouble() ?? 0.0,
      bassBoostFreq: (json['bassBoostFreq'] as num?)?.toDouble() ?? 80.0,
      loudnessEnabled: json['loudnessEnabled'] as bool? ?? false,
      loudnessGainDb: (json['loudnessGainDb'] as num?)?.toDouble() ?? 0.0,
      compressorEnabled: json['compressorEnabled'] as bool? ?? false,
      compressorThresholdDb: (json['compressorThresholdDb'] as num?)?.toDouble() ?? -12.0,
      compressorRatio: (json['compressorRatio'] as num?)?.toDouble() ?? 2.0,
      compressorAttackMs: (json['compressorAttackMs'] as num?)?.toDouble() ?? 10.0,
      compressorReleaseMs: (json['compressorReleaseMs'] as num?)?.toDouble() ?? 100.0,
      compressorMakeupGainDb: (json['compressorMakeupGainDb'] as num?)?.toDouble() ?? 0.0,
      stereoWidthEnabled: json['stereoWidthEnabled'] as bool? ?? false,
      stereoWidth: (json['stereoWidth'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class EQPreset {
  final String id;
  final String name;
  final String author;
  final String description;
  final bool isBuiltIn;
  bool enabled;
  double preampDb;
  List<EQBand> bands;
  DSPSettings dsp;
  bool isParametric;
  final int formatVersion;
  final DateTime createdAt;
  DateTime updatedAt;

  EQPreset({
    required this.id,
    required this.name,
    this.author = 'MDLovFi',
    this.description = '',
    this.isBuiltIn = false,
    this.enabled = true,
    this.preampDb = 0.0,
    required this.bands,
    DSPSettings? dsp,
    this.isParametric = false,
    this.formatVersion = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : dsp = dsp ?? DSPSettings(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  EQPreset copyWith({
    String? id,
    String? name,
    String? author,
    String? description,
    bool? isBuiltIn,
    bool? enabled,
    double? preampDb,
    List<EQBand>? bands,
    DSPSettings? dsp,
    bool? isParametric,
    int? formatVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EQPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      author: author ?? this.author,
      description: description ?? this.description,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      enabled: enabled ?? this.enabled,
      preampDb: preampDb ?? this.preampDb,
      bands: bands ?? this.bands.map((b) => b.copyWith()).toList(),
      dsp: dsp ?? this.dsp.copyWith(),
      isParametric: isParametric ?? this.isParametric,
      formatVersion: formatVersion ?? this.formatVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'author': author,
      'description': description,
      'isBuiltIn': isBuiltIn,
      'enabled': enabled,
      'preampDb': preampDb,
      'bands': bands.map((b) => b.toJson()).toList(),
      'dsp': dsp.toJson(),
      'isParametric': isParametric,
      'formatVersion': formatVersion,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory EQPreset.fromJson(Map<String, dynamic> json) {
    return EQPreset(
      id: json['id'] as String? ?? 'preset_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Custom Preset',
      author: json['author'] as String? ?? 'User',
      description: json['description'] as String? ?? '',
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      enabled: json['enabled'] as bool? ?? true,
      preampDb: (json['preampDb'] as num?)?.toDouble() ?? (json['preamp'] as num?)?.toDouble() ?? 0.0,
      bands: (json['bands'] as List<dynamic>?)
              ?.map((b) => EQBand.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
      dsp: json['dsp'] != null ? DSPSettings.fromJson(json['dsp'] as Map<String, dynamic>) : DSPSettings(),
      isParametric: json['isParametric'] as bool? ?? false,
      formatVersion: (json['formatVersion'] as num?)?.toInt() ?? 1,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }

  /// Exports into portable .mdleq JSON schema format as per PRD specification.
  Map<String, dynamic> toMdleqJson() {
    return {
      'format': 'mdlovfi-eq',
      'version': formatVersion,
      'name': name,
      'author': author,
      'description': description,
      'enabled': enabled,
      'preamp': preampDb,
      'isParametric': isParametric,
      'bands': bands.map((b) => b.toJson()).toList(),
      'dsp': dsp.toJson(),
    };
  }

  /// Parses from portable .mdleq JSON schema format.
  factory EQPreset.fromMdleqJson(Map<String, dynamic> json) {
    final format = json['format'] as String?;
    if (format != 'mdlovfi-eq' && format != 'mdlovfi_eq') {
      throw FormatException('Invalid format identifier: $format');
    }
    final bandsJson = json['bands'] as List<dynamic>?;
    if (bandsJson == null) {
      throw const FormatException('Missing bands array in preset');
    }

    return EQPreset(
      id: 'import_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Imported Preset',
      author: json['author'] as String? ?? 'External',
      description: json['description'] as String? ?? 'Imported from .mdleq file',
      isBuiltIn: false,
      enabled: json['enabled'] as bool? ?? true,
      preampDb: (json['preamp'] as num?)?.toDouble() ?? (json['preampDb'] as num?)?.toDouble() ?? 0.0,
      bands: bandsJson.map((b) => EQBand.fromJson(b as Map<String, dynamic>)).toList(),
      dsp: json['dsp'] != null ? DSPSettings.fromJson(json['dsp'] as Map<String, dynamic>) : DSPSettings(),
      isParametric: json['isParametric'] as bool? ?? false,
      formatVersion: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  String toMdleqString() => const JsonEncoder.withIndent('  ').convert(toMdleqJson());
}
