enum EqualizerFilterType {
  peaking,
  lowShelf,
  highShelf,
  lowPass,
  highPass,
  bandPass,
  notch,
}

extension EqualizerFilterTypeJson on EqualizerFilterType {
  String get value => switch (this) {
        EqualizerFilterType.peaking => 'peaking',
        EqualizerFilterType.lowShelf => 'lowShelf',
        EqualizerFilterType.highShelf => 'highShelf',
        EqualizerFilterType.lowPass => 'lowPass',
        EqualizerFilterType.highPass => 'highPass',
        EqualizerFilterType.bandPass => 'bandPass',
        EqualizerFilterType.notch => 'notch',
      };

  static EqualizerFilterType parse(Object? value) {
    return EqualizerFilterType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw const FormatException(
        'Unsupported equalizer filter type',
      ),
    );
  }
}

class EqualizerBand {
  static const double minFrequencyHz = 20;
  static const double maxFrequencyHz = 20000;
  static const double minGainDb = -15;
  static const double maxGainDb = 15;
  static const double minQ = 0.1;
  static const double maxQ = 20;

  final String id;
  final EqualizerFilterType type;
  final double frequency;
  final double gainDb;
  final double q;
  final bool enabled;

  const EqualizerBand({
    required this.id,
    required this.type,
    required this.frequency,
    required this.gainDb,
    required this.q,
    required this.enabled,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Band id must not be empty');
    }
    if (!frequency.isFinite ||
        frequency < minFrequencyHz ||
        frequency > maxFrequencyHz) {
      throw ArgumentError.value(
        frequency,
        'frequency',
        'Frequency must be between 20 Hz and 20 kHz',
      );
    }
    if (!gainDb.isFinite || gainDb < minGainDb || gainDb > maxGainDb) {
      throw ArgumentError.value(
        gainDb,
        'gainDb',
        'Gain must be between -15 dB and +15 dB',
      );
    }
    if (!q.isFinite || q < minQ || q > maxQ) {
      throw ArgumentError.value(
        q,
        'q',
        'Q must be between 0.1 and 20',
      );
    }
  }

  EqualizerBand copyWith({
    String? id,
    EqualizerFilterType? type,
    double? frequency,
    double? gainDb,
    double? q,
    bool? enabled,
  }) {
    return EqualizerBand(
      id: id ?? this.id,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      gainDb: gainDb ?? this.gainDb,
      q: q ?? this.q,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, Object> toJson() => {
        'id': id,
        'type': type.value,
        'frequency': frequency,
        'gainDb': gainDb,
        'q': q,
        'enabled': enabled,
      };

  factory EqualizerBand.fromJson(Map<String, Object?> json) {
    return EqualizerBand(
      id: _requireString(json, 'id'),
      type: EqualizerFilterTypeJson.parse(json['type']),
      frequency: _requireDouble(json, 'frequency'),
      gainDb: _requireDouble(json, 'gainDb'),
      q: _requireDouble(json, 'q'),
      enabled: _requireBool(json, 'enabled'),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EqualizerBand &&
        other.id == id &&
        other.type == type &&
        other.frequency == frequency &&
        other.gainDb == gainDb &&
        other.q == q &&
        other.enabled == enabled;
  }

  @override
  int get hashCode => Object.hash(
        id,
        type,
        frequency,
        gainDb,
        q,
        enabled,
      );
}

class EqualizerConfig {
  static const double minGlobalGainDb = -15;
  static const double maxGlobalGainDb = 15;

  final bool enabled;
  final double preampDb;
  final bool limiterEnabled;
  final double outputGainDb;
  final List<EqualizerBand> bands;

  EqualizerConfig({
    this.enabled = true,
    double preampDb = 0,
    this.limiterEnabled = true,
    double outputGainDb = 0,
    required List<EqualizerBand> bands,
  })  : preampDb = _clampGlobalGain(preampDb),
        outputGainDb = _clampGlobalGain(outputGainDb),
        bands = List.unmodifiable(bands);

  factory EqualizerConfig.graphic10Band() {
    const frequencies = [
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

    return EqualizerConfig(
      bands: [
        for (var i = 0; i < frequencies.length; i++)
          EqualizerBand(
            id: 'graphic-$i',
            type: EqualizerFilterType.peaking,
            frequency: frequencies[i],
            gainDb: 0,
            q: 1,
            enabled: true,
          ),
      ],
    );
  }

  EqualizerConfig copyWith({
    bool? enabled,
    double? preampDb,
    bool? limiterEnabled,
    double? outputGainDb,
    List<EqualizerBand>? bands,
  }) {
    return EqualizerConfig(
      enabled: enabled ?? this.enabled,
      preampDb: preampDb ?? this.preampDb,
      limiterEnabled: limiterEnabled ?? this.limiterEnabled,
      outputGainDb: outputGainDb ?? this.outputGainDb,
      bands: bands ?? this.bands,
    );
  }

  Map<String, Object> toJson() => {
        'format': 'mdlovfi-eq',
        'version': 1,
        'enabled': enabled,
        'preamp': preampDb,
        'outputGain': outputGainDb,
        'limiterEnabled': limiterEnabled,
        'bands': bands.map((band) => band.toJson()).toList(growable: false),
      };

  factory EqualizerConfig.fromJson(Map<String, Object?> json) {
    if (json['format'] != 'mdlovfi-eq') {
      throw const FormatException('Unsupported equalizer format');
    }

    final version = json['version'];
    if (version != 1) {
      throw FormatException('Unsupported equalizer format version: $version');
    }

    final rawBands = json['bands'];
    if (rawBands is! List) {
      throw const FormatException('Equalizer bands must be a list');
    }

    return EqualizerConfig(
      enabled: _requireBool(json, 'enabled'),
      preampDb: _requireDouble(json, 'preamp'),
      outputGainDb: _requireDouble(json, 'outputGain'),
      limiterEnabled: _requireBool(json, 'limiterEnabled'),
      bands: rawBands
          .map(
            (band) => EqualizerBand.fromJson(
              Map<String, Object?>.from(band as Map),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! EqualizerConfig ||
        other.enabled != enabled ||
        other.preampDb != preampDb ||
        other.limiterEnabled != limiterEnabled ||
        other.outputGainDb != outputGainDb ||
        other.bands.length != bands.length) {
      return false;
    }

    for (var i = 0; i < bands.length; i++) {
      if (bands[i] != other.bands[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        enabled,
        preampDb,
        limiterEnabled,
        outputGainDb,
        Object.hashAll(bands),
      );
}

double _clampGlobalGain(double value) {
  if (!value.isFinite) {
    throw ArgumentError.value(value, 'gain', 'Gain must be finite');
  }
  return value.clamp(
    EqualizerConfig.minGlobalGainDb,
    EqualizerConfig.maxGlobalGainDb,
  ).toDouble();
}

String _requireString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Expected string for $key');
  }
  return value;
}

double _requireDouble(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is num) return value.toDouble();
  throw FormatException('Expected number for $key');
}

bool _requireBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  throw FormatException('Expected boolean for $key');
}
