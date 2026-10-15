import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:terminate_restart/terminate_restart.dart';

import '/ui/screens/Settings/settings_screen_controller.dart';
import '/utils/helper.dart';
import 'common_dialog_widget.dart';

class RestoreDialog extends StatelessWidget {
  const RestoreDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final restoreDialogController = Get.put(RestoreDialogController());
    return CommonDialog(
      child: Container(
        height: 300,
        padding:
            const EdgeInsets.only(top: 20, bottom: 30, left: 20, right: 20),
        child: Stack(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.only(bottom: 10.0, top: 10),
                child: Text(
                  "restoreAppData".tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              SizedBox(
                height: 150,
                child: Center(
                  child: Obx(() => restoreDialogController.errorMessage.isNotEmpty
                      ? Text(restoreDialogController.errorMessage.value, textAlign: TextAlign.center)
                      : restoreDialogController.restoreProgress.toInt() ==
                          restoreDialogController.filesToRestore.toInt() &&
                          restoreDialogController.filesToRestore.value > 0
                      ? Text(
                          "restoreMsg".tr,
                          textAlign: TextAlign.center,
                        )
                      : restoreDialogController.processingFiles.isTrue
                          ? Text("processFiles".tr)
                          : restoreDialogController.restoreRunning.isTrue
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                        "${restoreDialogController.restoreProgress.toInt()}/${restoreDialogController.filesToRestore.toInt()}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Text("restoring".tr)
                                  ],
                                )
                              : Text("letsStrart".tr)),
                ),
              ),
              SizedBox(
                width: double.maxFinite,
                child: Align(
                  child: Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context).textTheme.titleLarge!.color,
                        borderRadius: BorderRadius.circular(10)),
                    child: InkWell(
                      onTap: () {
                        if (restoreDialogController.restoreProgress.toInt() ==
                            restoreDialogController.filesToRestore.toInt()) {
                          GetPlatform.isAndroid
                              ? TerminateRestart.instance.restartApp(
                                  options: const TerminateRestartOptions(
                                    terminate: true,
                                  ),
                                )
                              : exit(0);
                        } else {
                          restoreDialogController.restore();
                        }
                      },
                      child: Obx(
                        () => Visibility(
                          visible: restoreDialogController
                                  .processingFiles.isFalse &&
                              restoreDialogController.restoreRunning.isFalse,
                          replacement: const SizedBox(
                            height: 40,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15.0, vertical: 10),
                            child: Obx(
                              () => Text(
                                restoreDialogController.restoreProgress
                                            .toInt() ==
                                        restoreDialogController.filesToRestore
                                            .toInt()
                                    ? "restartApp".tr
                                    : "restore".tr,
                                style: TextStyle(
                                    color: Theme.of(context).canvasColor),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class RestoreDialogController extends GetxController {
  final restoreRunning = false.obs;
  final restoreProgress = (-1).obs;
  final filesToRestore = (0).obs;
  final processingFiles = false.obs;
  final errorMessage = ''.obs;

  Future<void> restore() async {
    if (processingFiles.value || restoreRunning.value) return;
    errorMessage.value = '';
    try {
      // The system picker grants access to the selected backup file. No
      // broad external-storage permission is needed for app-private data.
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select backup file',
        type: FileType.custom,
        allowedExtensions: ['muziinap'],
        allowMultiple: false,
        withData: false,
      );
      if (result == null || result.files.isEmpty || result.files.first.path == null) return;
      final restoreFilePath = result.files.first.path!;
      processingFiles.value = true;
      final bytes = await File(restoreFilePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes, verify: true);
      final files = archive.files.where((file) => file.isFile).toList();
      if (files.isEmpty || !files.any((file) => file.name.endsWith('.hive'))) {
        throw const FormatException('The selected file is not a valid app backup.');
      }
      final settings = Get.find<SettingsScreenController>();
      final supportDirPath = settings.supportDirPath;
      final dbDirPath = await settings.dbDir;
      final dbDir = Directory(dbDirPath);
      await dbDir.create(recursive: true);
      // Do not delete existing databases until the archive has been validated.
      await settings.closeAllDatabases();
      for (final entity in await dbDir.list().toList()) {
        if (entity is File && entity.path.endsWith('.hive')) await entity.delete();
      }
      filesToRestore.value = files.length;
      restoreProgress.value = 0;
      processingFiles.value = false;
      restoreRunning.value = true;
      for (final file in files) {
        final filename = file.name.split('/').last;
        if (filename.isEmpty || filename == '.' || filename == '..') continue;
        final data = file.content as List<int>;
        final targetDir = filename.endsWith('.m4a') || filename.endsWith('.opus')
            ? '$supportDirPath/Music'
            : filename.endsWith('.png')
                ? '$supportDirPath/thumbnails'
                : dbDirPath;
        final outputFile = File('$targetDir/$filename');
        await outputFile.parent.create(recursive: true);
        await outputFile.writeAsBytes(data, flush: true);
        restoreProgress.value++;
      }
      final tempPath = '${(await getApplicationCacheDirectory()).path}/file_picker';
      final tempDir = Directory(tempPath);
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
      if (GetPlatform.isWindows || GetPlatform.isLinux) {
        final songBox = await Hive.openBox('SongDownloads');
        for (final song in songBox.values.toList()) {
          if (song is Map) {
            final songPath = song['url'];
            if (songPath is String) {
              final fileName = songPath.split('/').last;
              final newPath = '$supportDirPath/Music/$fileName';
              song['url'] = newPath;
              final streamInfo = song['streamInfo'];
              if (streamInfo is List && streamInfo.length > 1 && streamInfo[1] is Map) {
                streamInfo[1]['url'] = newPath;
              }
              final videoId = song['videoId'];
              if (videoId != null) await songBox.put(videoId, song);
            }
          }
        }
      }
    } catch (e) {
      errorMessage.value = 'Restore failed: $e';
      printERROR(errorMessage.value);
    } finally {
      processingFiles.value = false;
      restoreRunning.value = false;
    }
  }
}
