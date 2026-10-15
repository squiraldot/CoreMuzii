import '../../../services/constant.dart';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import 'package:mdlovfimusic/services/permission_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../utils/update_check_flag_file.dart';
import '/services/piped_service.dart';
import '../Library/library_controller.dart';
import '../../widgets/snackbar.dart';
import '../../../utils/helper.dart';
import '/services/music_service.dart';
import '/ui/player/player_controller.dart';
import '../Home/home_screen_controller.dart';
import '/ui/utils/theme_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'settings_preferences.dart';

class SettingsScreenController extends GetxController {
  late String _supportDir;
  final cacheSongs = false.obs;
  final setBox = Hive.box(appPrefsBoxName);
  final themeModetype = ThemeType.dynamic.obs;
  final skipSilenceEnabled = false.obs;
  final loudnessNormalizationEnabled = false.obs;
  final noOfHomeScreenContent = 3.obs;
  final streamingQuality = AudioQuality.High.obs;
  final playerUi = 0.obs;
  final slidableActionEnabled = true.obs;
  final isIgnoringBatteryOptimizations = false.obs;
  final autoOpenPlayer = false.obs;
  final discoverContentType = "QP".obs;
  final isNewVersionAvailable = false.obs;
  final isLinkedWithPiped = false.obs;
  final stopPlyabackOnSwipeAway = false.obs;
  final currentAppLanguageCode = "en".obs;
  final downloadLocationPath = "".obs;
  final exportLocationPath = "".obs;
  final downloadingFormat = "".obs;
  final autoDownloadFavoriteSongEnabled = false.obs;
  final isTransitionAnimationDisabled = false.obs;
  final isBottomNavBarEnabled = (!GetPlatform.isDesktop).obs;
  final backgroundPlayEnabled = true.obs;
  final keepScreenAwake = false.obs;
  final restorePlaybackSession = false.obs;
  final cacheHomeScreenData = true.obs;
  final currentVersion = "V1.13.3";

  @override
  void onInit() {
    super.onInit();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    try {
      await _setInitValue();
      await _createInAppSongDownDir();
    } catch (e) {
      printERROR("Failed to initialize settings: $e");
    }
    if (updateCheckFlag) _checkNewVersion();
  }

  get currentVision => currentVersion;
  get isCurrentPathsupportDownDir =>
      "$_supportDir/Music" == downloadLocationPath.toString();
  String get supportDirPath => _supportDir;

  _checkNewVersion() {
    newVersionCheck(currentVersion)
        .then((value) => isNewVersionAvailable.value = value);
  }

  Future<String> _createInAppSongDownDir() async {
    _supportDir = (await getApplicationSupportDirectory()).path;
    final directory = Directory("$_supportDir/Music/");
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return "$_supportDir/Music";
  }

  Future<void> _setInitValue() async {
    final isDesktop = GetPlatform.isDesktop;
    final appLang = setBox.get('currentAppLanguageCode') ?? "en";
    currentAppLanguageCode.value = appLang == "zh_Hant"
        ? "zh-TW"
        : appLang == "zh_Hans"
            ? "zh-CN"
            : appLang;
    final storedBottomNavBarEnabled = setBox.get("isBottomNavBarEnabled");
    isBottomNavBarEnabled.value = resolveBottomNavBarPreference(
      isDesktop: isDesktop,
      storedValue: storedBottomNavBarEnabled,
    );
    final shouldPersistBottomNavDefault =
        !isDesktop && storedBottomNavBarEnabled == null;
    noOfHomeScreenContent.value = setBox.get("noOfHomeScreenContent") ?? 3;
    isTransitionAnimationDisabled.value =
        setBox.get("isTransitionAnimationDisabled") ?? false;
    cacheSongs.value = setBox.get('cacheSongs') ?? false;
    themeModetype.value = ThemeType.values[setBox.get('themeModeType') ?? 0];
    skipSilenceEnabled.value =
        isDesktop ? false : (setBox.get("skipSilenceEnabled") ?? false);
    loudnessNormalizationEnabled.value = isDesktop
        ? false
        : (setBox.get("loudnessNormalizationEnabled") ?? false);
    autoOpenPlayer.value = (setBox.get("autoOpenPlayer") ?? true);
    restorePlaybackSession.value =
        setBox.get("restrorePlaybackSession") ?? false;
    cacheHomeScreenData.value = setBox.get("cacheHomeScreenData") ?? true;
    playerUi.value = isDesktop ? 0 : (setBox.get('playerUi') ?? 0);
    backgroundPlayEnabled.value = setBox.get("backgroundPlayEnabled") ?? true;
    keepScreenAwake.value =
        setBox.get("keepScreenAwake") ?? (GetPlatform.isDesktop ? true : false);
    // Read synchronous preferences before the first await, so late
    // initialization cannot overwrite a user's tap with stale values.
    exportLocationPath.value =
        setBox.get("exportLocationPath") ?? "/storage/emulated/0/Music";
    downloadingFormat.value = setBox.get('downloadingFormat') ?? "m4a";
    discoverContentType.value = setBox.get('discoverContentType') ?? "QP";
    slidableActionEnabled.value = setBox.get('slidableActionEnabled') ?? true;
    if (setBox.containsKey("piped")) {
      isLinkedWithPiped.value = setBox.get("piped")['isLoggedIn'];
    }
    stopPlyabackOnSwipeAway.value =
        setBox.get('stopPlyabackOnSwipeAway') ?? false;
    autoDownloadFavoriteSongEnabled.value =
        setBox.get("autoDownloadFavoriteSongEnabled") ?? false;

    final storedQualityIndex = setBox.get('streamingQuality') ?? 1;
    final safeQualityIndex = storedQualityIndex is int &&
            storedQualityIndex >= 0 &&
            storedQualityIndex < AudioQuality.values.length
        ? storedQualityIndex
        : 1;
    streamingQuality.value = AudioQuality.values[safeQualityIndex];

    final storedDownloadPath = setBox.get('downloadLocationPath');
    final downloadPath = storedDownloadPath is String &&
            storedDownloadPath.isNotEmpty
        ? storedDownloadPath
        : await _createInAppSongDownDir();
    downloadLocationPath.value =
        (isDesktop && downloadPath.contains("emulated"))
            ? await _createInAppSongDownDir()
            : downloadPath;

    if (GetPlatform.isAndroid) {
      isIgnoringBatteryOptimizations.value =
          await Permission.ignoreBatteryOptimizations.isGranted;
    }

    // Persist this migration default only after all synchronous preferences
    // have been loaded. Awaiting Hive here earlier yielded control while the
    // remaining Rx settings still held defaults, allowing early UI taps to be
    // overwritten by stale values later in initialization.
    if (shouldPersistBottomNavDefault) {
      await setBox.put("isBottomNavBarEnabled", true);
    }
  }

  Future<void> setAppLanguage(String? val) async {
    if (val == null || val.isEmpty) return;
    Get.updateLocale(Locale(val));
    final musicServices = Get.find<MusicServices>();
    musicServices.hlCode = val;
    final country = Get.deviceLocale?.countryCode ?? 'US';
    musicServices.glCode = country;
    currentAppLanguageCode.value = val;
    await setBox.put('currentAppLanguageCode', val);
    await setBox.put('contentLanguage', val);
    await setBox.put('contentCountryCode', country);
    await Get.find<HomeScreenController>().refreshHome();
  }

  Future<void> setContentNumber(int? no) async {
    noOfHomeScreenContent.value = no!;
    await setBox.put("noOfHomeScreenContent", no);
  }

  Future<void> setStreamingQuality(dynamic val) async {
    if (val is! AudioQuality) return;
    final index = AudioQuality.values.indexOf(val);
    if (index < 0) return;
    await setBox.put("streamingQuality", index);
    streamingQuality.value = val;
  }

  Future<void> setPlayerUi(dynamic val) async {
    final playerCon = Get.find<PlayerController>();
    await setBox.put("playerUi", val);
    if (val == 1 && playerCon.gesturePlayerStateAnimationController == null) {
      playerCon.initGesturePlayerStateAnimationController();
    }

    playerUi.value = val;
  }

  Future<void> enableBottomNavBar(bool val) async {
    final homeScrCon = Get.find<HomeScreenController>();
    final playerCon = Get.find<PlayerController>();
    if (val) {
      homeScrCon.onSideBarTabSelected(3);
      isBottomNavBarEnabled.value = true;
    } else {
      isBottomNavBarEnabled.value = false;
      homeScrCon.onSideBarTabSelected(5);
    }
    if (!Get.find<PlayerController>().initFlagForPlayer) {
      playerCon.playerPanelMinHeight.value =
          val ? 75.0 : 75.0 + Get.mediaQuery.viewPadding.bottom;
    }
    await setBox.put("isBottomNavBarEnabled", val);
  }

  Future<void> toggleSlidableAction(bool val) async {
    await setBox.put("slidableActionEnabled", val);
    slidableActionEnabled.value = val;
  }

  Future<void> changeDownloadingFormat(String? val) async {
    await setBox.put("downloadingFormat", val);
    downloadingFormat.value = val!;
  }

  Future<void> setExportedLocation() async {
    if (!await PermissionService.getExtStoragePermission()) {
      return;
    }

    final String? pickedFolderPath = await FilePicker.platform
        .getDirectoryPath(dialogTitle: "Select export file folder");
    if (pickedFolderPath == '/' || pickedFolderPath == null) {
      return;
    }

    await setBox.put("exportLocationPath", pickedFolderPath);
    exportLocationPath.value = pickedFolderPath;
  }

  Future<void> setDownloadLocation() async {
    if (!await PermissionService.getExtStoragePermission()) {
      return;
    }

    final String? pickedFolderPath = await FilePicker.platform
        .getDirectoryPath(dialogTitle: "Select downloads folder");
    if (pickedFolderPath == '/' || pickedFolderPath == null) {
      return;
    }

    await setBox.put("downloadLocationPath", pickedFolderPath);
    downloadLocationPath.value = pickedFolderPath;
  }

  Future<void> disableTransitionAnimation(bool val) async {
    await setBox.put('isTransitionAnimationDisabled', val);
    isTransitionAnimationDisabled.value = val;
  }

  Future<void> clearImagesCache() async {
    final tempImgDirPath =
        "${(await getApplicationCacheDirectory()).path}/libCachedImageData";
    final tempImgDir = Directory(tempImgDirPath);
    try {
      if (await tempImgDir.exists()) {
        await tempImgDir.delete(recursive: true);
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<void> resetDownloadLocation() async {
    final defaultPath = "$_supportDir/Music";
    await setBox.put("downloadLocationPath", defaultPath);
    downloadLocationPath.value = defaultPath;
  }

  Future<void> onThemeChange(dynamic val) async {
    await setBox.put('themeModeType', ThemeType.values.indexOf(val));
    themeModetype.value = val;
    Get.find<ThemeController>().changeThemeModeType(val);
  }

  Future<void> onContentChange(dynamic value) async {
    await setBox.put('discoverContentType', value);
    discoverContentType.value = value;
    Get.find<HomeScreenController>().changeDiscoverContent(value);
  }

  Future<void> toggleCachingSongsValue(bool value) async {
    await setBox.put("cacheSongs", value);
    cacheSongs.value = value;
  }

  Future<void> toggleSkipSilence(bool val) async {
    final playerController = Get.find<PlayerController>();
    // Apply the player setting before publishing it as enabled in Settings.
    await playerController.toggleSkipSilence(val);
    await setBox.put('skipSilenceEnabled', val);
    skipSilenceEnabled.value = val;
  }

  Future<void> toggleLoudnessNormalization(bool val) async {
    final playerController = Get.find<PlayerController>();
    // Wait for the audio service to apply the change so rapid toggles cannot
    // leave the UI and actual player in different states.
    await playerController.toggleLoudnessNormalization(val);
    await setBox.put("loudnessNormalizationEnabled", val);
    loudnessNormalizationEnabled.value = val;
  }

  Future<void> toggleRestorePlaybackSession(bool val) async {
    await setBox.put("restrorePlaybackSession", val);
    restorePlaybackSession.value = val;
  }

  Future<void> toggleCacheHomeScreenData(bool val) async {
    await setBox.put("cacheHomeScreenData", val);
    cacheHomeScreenData.value = val;
    if (!val) {
      final box = await Hive.openBox("homeScreenData");
      await box.clear();
      await box.close();
    } else {
      await Hive.openBox("homeScreenData");
      await Get.find<HomeScreenController>()
          .cachedHomeScreenData(updateAll: true);
    }
  }

  Future<void> toggleAutoDownloadFavoriteSong(bool val) async {
    await setBox.put("autoDownloadFavoriteSongEnabled", val);
    autoDownloadFavoriteSongEnabled.value = val;
  }

  Future<void> toggleBackgroundPlay(bool val) async {
    await setBox.put('backgroundPlayEnabled', val);
    backgroundPlayEnabled.value = val;
  }

  Future<void> toggleKeepScreenAwake(bool val) async {
    try {
      final player = Get.find<PlayerController>();
      if (val && player.buttonState.value == PlayButtonState.playing) {
        await WakelockPlus.enable();
      } else if (!val) {
        await WakelockPlus.disable();
      }
      await setBox.put('keepScreenAwake', val);
      keepScreenAwake.value = val;
    } catch (e) {
      printERROR("Failed to update keep-screen-awake setting: $e");
      // Keep the preference usable even if the platform wakelock API fails.
      await setBox.put('keepScreenAwake', val);
      keepScreenAwake.value = val;
    }
  }

  Future<void> enableIgnoringBatteryOptimizations() async {
    await Permission.ignoreBatteryOptimizations.request();
    isIgnoringBatteryOptimizations.value =
        await Permission.ignoreBatteryOptimizations.isGranted;
  }

  Future<void> toggleAutoOpenPlayer(bool val) async {
    await setBox.put('autoOpenPlayer', val);
    autoOpenPlayer.value = val;
  }

  Future<void> unlinkPiped() async {
    Get.find<PipedServices>().logout();
    isLinkedWithPiped.value = false;
    Get.find<LibraryPlaylistsController>().removePipedPlaylists();
    final box = await Hive.openBox('blacklistedPlaylist');
    box.clear();
    ScaffoldMessenger.of(Get.context!).showSnackBar(
        snackbar(Get.context!, "unlinkAlert".tr, size: SanckBarSize.MEDIUM));
    box.close();
  }

  Future<void> resetAppSettingsToDefault() async {
    // Clear storage first, then reload defaults before applying runtime changes.
    await setBox.clear();
    await _setInitValue();

    // Clearing Hive alone does not change settings already applied to the player.
    final playerController = Get.find<PlayerController>();
    await playerController.toggleSkipSilence(false);
    await playerController.toggleLoudnessNormalization(false);
    await Get.find<AudioHandler>().customAction("resetEqualizer");
    await toggleKeepScreenAwake(keepScreenAwake.value);
  }

  Future<void> toggleStopPlyabackOnSwipeAway(bool val) async {
    await setBox.put('stopPlyabackOnSwipeAway', val);
    stopPlyabackOnSwipeAway.value = val;
  }

  Future<void> closeAllDatabases() async {
    await Hive.close();
  }

  Future<String> get dbDir async {
    if (GetPlatform.isDesktop) {
      return "$supportDirPath/db";
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }
}
