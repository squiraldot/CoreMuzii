import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../services/constant.dart';

class TemporarySongInfoDialog extends StatelessWidget {
  const TemporarySongInfoDialog({
    super.key,
    required this.song,
  });

  final MediaItem song;

  @override
  Widget build(BuildContext context) {
    final streamInfo = _readStreamInfo(song.id);
    final durationValue =
        streamInfo['approxDurationMs'] ?? song.duration?.inMilliseconds;

    final items = <_SongInfoRowData>[
      _SongInfoRowData('ID', song.id),
      _SongInfoRowData('Title', song.title),
      _SongInfoRowData('Album', _stringOrNA(song.album)),
      _SongInfoRowData('Artists', _stringOrNA(song.artist)),
      _SongInfoRowData(
        'Duration',
        _displayValue(durationValue, suffix: ' ms'),
      ),
      _SongInfoRowData(
        'Audio codec',
        _displayValue(streamInfo['audioCodec']),
      ),
      _SongInfoRowData(
        'Bitrate',
        _displayValue(streamInfo['bitrate']),
      ),
      _SongInfoRowData(
        'Loudness',
        _displayValue(streamInfo['loudnessDb']),
      ),
    ];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Song Info',
                key: Key('temporary_song_info_title'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  key: const Key('temporary_song_info_list'),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _SongInfoRow(data: item);
                  },
                ),
              ),
              const Divider(height: 1),
              SizedBox(
                height: 52,
                child: TextButton(
                  key: const Key('temporary_song_info_close'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _stringOrNA(String? value) {
    if (value == null) return 'NA';
    final text = value.trim();
    return text.isEmpty ? 'NA' : text;
  }

  static String _displayValue(dynamic value, {String suffix = ''}) {
    if (value == null) return 'NA';
    final text = value.toString().trim();
    return text.isEmpty ? 'NA' : '$text$suffix';
  }

  Map<String, dynamic> _readStreamInfo(String id) {
    final downloads = _readFromDownloads(id);
    if (downloads.isNotEmpty) return downloads;

    return _readFromCache(id);
  }

  Map<String, dynamic> _readFromDownloads(String id) {
    try {
      if (!Hive.isBoxOpen('SongDownloads')) return const {};
      final data = Hive.box('SongDownloads').get(id);
      if (data is! Map) return const {};

      final raw = data['streamInfo'];
      if (raw is List && raw.length > 1 && raw[1] is Map) {
        return Map<String, dynamic>.from(raw[1] as Map);
      }
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
    } catch (_) {
      // Optional cache data must never prevent the dialog from rendering.
    }
    return const {};
  }

  Map<String, dynamic> _readFromCache(String id) {
    try {
      if (!Hive.isBoxOpen('SongsUrlCache')) return const {};
      final cache = Hive.box('SongsUrlCache').get(id);
      if (cache is! Map) return const {};

      final quality =
          Hive.isBoxOpen(appPrefsBoxName)
              ? Hive.box(appPrefsBoxName).get('streamingQuality')
              : null;
      final qualityKey =
          quality == 0 ? 'lowQualityAudio' : 'highQualityAudio';
      final selected = cache[qualityKey];

      if (selected is Map) {
        return Map<String, dynamic>.from(selected);
      }
    } catch (_) {
      // Optional cache data must never prevent the dialog from rendering.
    }
    return const {};
  }
}

class _SongInfoRowData {
  const _SongInfoRowData(this.label, this.value);

  final String label;
  final String value;
}

class _SongInfoRow extends StatelessWidget {
  const _SongInfoRow({required this.data});

  final _SongInfoRowData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            data.value,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
