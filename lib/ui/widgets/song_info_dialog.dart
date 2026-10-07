import '../../services/constant.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';


class SongInfoDialog extends StatelessWidget {
  final MediaItem song;
  const SongInfoDialog({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final streamInfo = _getStreamInfo(song.id);
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;

    return Dialog(
      backgroundColor: surfaceColor,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: Get.mediaQuery.size.height * .72,
          minWidth: 280,
        ),
        child: Material(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Text("songInfo".tr,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: textColor,
                  )),
            ),
            const Divider(),
            Expanded(
                child: ListView(
              children: [
                InfoItem(title: "id".tr, value: song.id),
                InfoItem(title: "title".tr, value: song.title),
                InfoItem(title: "album".tr, value: song.album ?? "NA"),
                InfoItem(title: "artists".tr, value: song.artist ?? "NA"),
                InfoItem(
                    title: "duration".tr,
                    value:
                        "${streamInfo["approxDurationMs"] ?? song.duration?.inMilliseconds ?? "NA"} ms"),
                InfoItem(
                    title: "audioCodec".tr,
                    value: streamInfo["audioCodec"] ?? "NA"),
                InfoItem(
                    title: "bitrate".tr,
                    value: "${streamInfo["bitrate"] ?? "NA"}"),
                InfoItem(
                    title: "loudnessDb".tr,
                    value: "${streamInfo["loudnessDb"] ?? "NA"}"),
              ],
            )),
            const Divider(),
            SizedBox(
              height: 50,
              child: Align(
                alignment: Alignment.center,
                child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 25),
                      child: Text(
                      "close".tr,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: textColor,
                      ),
                    ),
                    )),
              ),
            )
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStreamInfo(String id) {
    const nullVal = <String, dynamic>{
      "audioCodec": null,
      "bitrate": null,
      "loudnessDb": null,
      "approxDurationMs": null,
    };

    try {
      final downloads = Hive.box("SongDownloads");
      if (downloads.containsKey(id)) {
        final downloadedSong = downloads.get(id);
        final rawStreamInfo = downloadedSong is Map
            ? downloadedSong["streamInfo"]
            : null;

        if (rawStreamInfo is List && rawStreamInfo.length > 1) {
          final selected = rawStreamInfo[1];
          if (selected is Map) {
            return Map<String, dynamic>.from(selected);
          }
        }
        if (rawStreamInfo is Map) {
          return Map<String, dynamic>.from(rawStreamInfo);
        }
        return nullVal;
      }

      final dbStreamData = Hive.box("SongsUrlCache").get(id);
      if (dbStreamData is! Map) return nullVal;

      final qualityKey =
          Hive.box(appPrefsBoxName).get('streamingQuality') == 0
              ? 'lowQualityAudio'
              : 'highQualityAudio';
      final selected = dbStreamData[qualityKey];
      if (selected is Map) {
        return Map<String, dynamic>.from(selected);
      }
    } catch (_) {
      // Stream metadata is optional. Never let malformed cache data break
      // the song info dialog.
    }

    return nullVal;
  }
}

class InfoItem extends StatelessWidget {
  final String title;
  final String value;
  const InfoItem({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: TextAlign.start,
          ),
          TextSelectionTheme(
            data: Theme.of(context).textSelectionTheme,
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          )
        ],
      ),
    );
  }
}
