import '../../services/constant.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/ui/widgets/common_dialog_widget.dart';

class SongInfoDialog extends StatelessWidget {
  final MediaItem song;
  const SongInfoDialog({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final streamInfo = _getStreamInfo(song.id);
    return CommonDialog(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Text("songInfo".tr,
                  style: Theme.of(context).textTheme.titleLarge),
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
                    value: "${streamInfo["audioCodec"] ?? "NA"}"),
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
                      child: Text("close".tr),
                    )),
              ),
            )
          ],
        ),
      ),
    );
  }

  Map<dynamic, dynamic> _getStreamInfo(String id) {
    final nullVal = <dynamic, dynamic>{
      "audioCodec": null,
      "bitrate": null,
      "loudnessDb": null,
      "approxDurationMs": null
    };

    if (Hive.box("SongDownloads").containsKey(id)) {
      final songData = Hive.box("SongDownloads").get(id);
      if (songData is Map &&
          songData["streamInfo"] is List &&
          (songData["streamInfo"] as List).length > 1) {
        final info = songData["streamInfo"][1];
        if (info is Map) {
          return info;
        }
      }
      return nullVal;
    }

    final dbStreamData = Hive.box("SongsUrlCache").get(id);
    if (dbStreamData is Map) {
      final qualitySetting = Hive.box(appPrefsBoxName).get('streamingQuality');
      final qualityKey =
          qualitySetting == 0 ? 'lowQualityAudio' : 'highQualityAudio';
      final audioData = dbStreamData[qualityKey];
      if (audioData is Map) {
        return audioData;
      }
      final fallbackKey =
          qualitySetting == 0 ? 'highQualityAudio' : 'lowQualityAudio';
      final fallbackAudioData = dbStreamData[fallbackKey];
      if (fallbackAudioData is Map) {
        return fallbackAudioData;
      }
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
