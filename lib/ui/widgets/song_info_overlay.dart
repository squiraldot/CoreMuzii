import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../services/constant.dart';

/// An in-place song info surface.
///
/// This intentionally does not use Dialog, showDialog, showModalBottomSheet,
/// Navigator, or BackdropFilter. It is rendered directly in the Player's
/// existing widget tree so Android route/compositing bugs cannot blank the
/// player when Song Info is opened.
class SongInfoOverlay extends StatelessWidget {
  const SongInfoOverlay({
    super.key,
    required this.song,
    required this.onClose,
  });

  final MediaItem song;
  final VoidCallback onClose;

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
      _SongInfoRowData('Duration', _displayValue(durationValue, suffix: ' ms')),
      _SongInfoRowData('Audio codec', _displayValue(streamInfo['audioCodec'])),
      _SongInfoRowData('Bitrate', _displayValue(streamInfo['bitrate'])),
      _SongInfoRowData('Loudness', _displayValue(streamInfo['loudnessDb'])),
    ];

    return Positioned.fill(
      child: Material(
        color: Colors.black54,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                  maxHeight: 600,
                ),
                child: Material(
                  elevation: 12,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  color: Theme.of(context).cardColor,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Song Info',
                                key: Key('song_info_overlay_title'),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              key: const Key('song_info_overlay_close'),
                              tooltip: 'Close',
                              onPressed: onClose,
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          key: const Key('song_info_overlay_list'),
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 4),
                          itemBuilder: (context, index) =>
                              _SongInfoRow(data: items[index]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
    } catch (_) {}
    return const {};
  }

  Map<String, dynamic> _readFromCache(String id) {
    try {
      if (!Hive.isBoxOpen('SongsUrlCache')) return const {};
      final cache = Hive.box('SongsUrlCache').get(id);
      if (cache is! Map) return const {};

      final quality = Hive.isBoxOpen(appPrefsBoxName)
          ? Hive.box(appPrefsBoxName).get('streamingQuality')
          : null;
      final qualityKey = quality == 0 ? 'lowQualityAudio' : 'highQualityAudio';
      final selected = cache[qualityKey];

      if (selected is Map) {
        return Map<String, dynamic>.from(selected);
      }
    } catch (_) {}
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

  final _SongInfoRowData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.label, maxLines: 1, overflow: TextOverflow.ellipsis),
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
