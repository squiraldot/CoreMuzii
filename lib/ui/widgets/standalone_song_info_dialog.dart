import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../services/constant.dart';

/// Experimental, standalone Song Info dialog.
///
/// This widget intentionally has no dependency on the legacy Song Info
/// bottom-sheet/dialog implementation. It owns its layout and metadata
/// normalization so optional cache values cannot break rendering.
class StandaloneSongInfoDialog extends StatelessWidget {
  final MediaItem song;

  const StandaloneSongInfoDialog({
    super.key,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = (size.width - 32).clamp(280.0, 560.0).toDouble();
    final height = (size.height - 48).clamp(280.0, 620.0).toDouble();
    final metadata = _readMetadata(song);

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Theme.of(context).dialogTheme.backgroundColor ??
            Theme.of(context).colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'songInfo'.tr,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'close'.tr,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                itemCount: metadata.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = metadata[index];
                  return _MetadataRow(
                    label: item.label,
                    value: item.value,
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('close'.tr),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<_MetadataValue> _readMetadata(MediaItem song) {
    final stream = _readOptionalStreamMetadata(song.id);

    return [
      _MetadataValue('ID', _asText(song.id)),
      _MetadataValue('Title', _asText(song.title)),
      _MetadataValue('Album', _asText(song.album)),
      _MetadataValue('Artist', _asText(song.artist)),
      _MetadataValue(
        'Duration',
        _asText(
          stream['approxDurationMs'] ??
              song.duration?.inMilliseconds,
          suffix: ' ms',
        ),
      ),
      _MetadataValue('Audio codec', _asText(stream['audioCodec'])),
      _MetadataValue('Bitrate', _asText(stream['bitrate'])),
      _MetadataValue('Loudness (dB)', _asText(stream['loudnessDb'])),
    ];
  }

  static Map<String, dynamic> _readOptionalStreamMetadata(String id) {
    const empty = <String, dynamic>{};

    if (id.isEmpty) return empty;

    final fromDownloads = _readDownloads(id);
    if (fromDownloads.isNotEmpty) return fromDownloads;

    final fromCache = _readUrlCache(id);
    if (fromCache.isNotEmpty) return fromCache;

    return empty;
  }

  static Map<String, dynamic> _readDownloads(String id) {
    if (!Hive.isBoxOpen('SongDownloads')) return const {};

    try {
      final box = Hive.box('SongDownloads');
      final entry = box.get(id);
      if (entry is! Map) return const {};

      final raw = entry['streamInfo'];
      if (raw is Map) return _normalizeMap(raw);
      if (raw is List && raw.length > 1 && raw[1] is Map) {
        return _normalizeMap(raw[1]);
      }
    } catch (_) {
      // Download metadata is optional; rendering must continue with NA values.
    }

    return const {};
  }

  static Map<String, dynamic> _readUrlCache(String id) {
    if (!Hive.isBoxOpen('SongsUrlCache')) return const {};

    try {
      final box = Hive.box('SongsUrlCache');
      final entry = box.get(id);
      if (entry is! Map) return const {};

      final quality = _readStreamingQuality();
      final preferredKey =
          quality == 0 ? 'lowQualityAudio' : 'highQualityAudio';
      final fallbackKey =
          preferredKey == 'highQualityAudio'
              ? 'lowQualityAudio'
              : 'highQualityAudio';

      final preferred = entry[preferredKey];
      if (preferred is Map) return _normalizeMap(preferred);

      final fallback = entry[fallbackKey];
      if (fallback is Map) return _normalizeMap(fallback);
    } catch (_) {
      // Cache metadata is optional; rendering must continue with NA values.
    }

    return const {};
  }

  static int? _readStreamingQuality() {
    if (!Hive.isBoxOpen(appPrefsBoxName)) return null;

    try {
      final raw = Hive.box(appPrefsBoxName).get('streamingQuality');
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      return int.tryParse(raw?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _normalizeMap(Map raw) {
    final result = <String, dynamic>{};
    raw.forEach((key, value) {
      if (key != null) {
        result[key.toString()] = value;
      }
    });
    return result;
  }

  static String _asText(
    dynamic value, {
    String suffix = '',
  }) {
    if (value == null) return 'NA';

    final normalized = value.toString().trim();
    if (normalized.isEmpty) return 'NA';

    return '$normalized$suffix';
  }
}

class _MetadataValue {
  final String label;
  final String value;

  const _MetadataValue(this.label, this.value);
}

class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetadataRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 108,
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SelectableText(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
