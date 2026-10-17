# Copilot Instructions for MuziiNap

## Project Overview

MuziiNap is an **Android-only** music streaming application built with Flutter. It streams music from YouTube/YouTube Music without requiring app login or showing advertisements. Keep changes compatible with supported Android phones, tablets, and foldables.

## Technology Stack

- **Framework**: Flutter (Dart SDK >=3.1.5 <4.0.0; use the Flutter version pinned by the relevant GitHub Actions workflow)
- **State Management**: GetX (`get: ^4.7.1`)
- **Audio Playback**: `just_audio` with `audio_service` for Android background playback and media controls
- **Local Storage**: Hive (`hive`, `hive_flutter`)
- **YouTube API**: `youtube_explode_dart` custom fork
- **HTTP Client**: dio
- **UI Components**: animations, cached_network_image, flutter_slidable, shimmer
- **Native Android integration**: JNI/JNIGen bindings, Android equalizer, camera/QR scanning

## Project Structure

```
lib/
├── base_class/      # Base classes and abstractions
├── mixins/          # Reusable mixins
├── models/          # Data models
├── native_bindings/ # Android native code bindings
├── services/        # Audio, music, downloader, equalizer, and network services
├── ui/              # User interface
│   ├── player/      # Music player UI and controllers
│   ├── screens/     # Home, Library, Settings, Search, and other screens
│   ├── utils/       # UI utilities
│   └── widgets/     # Reusable widgets
└── utils/           # General utilities and helpers
```

## Key Controllers (GetX)

- `PlayerController` - Manages music playback and queue
- `HomeScreenController` - Home screen state
- `LibraryController` - Library and collection management
- `SettingsScreenController` - App settings
- `SearchScreenController` - Search functionality
- `ThemeController` - Dynamic theming

## Architecture Patterns

- **State Management**: GetX controllers and reactive state
- **Dependency Injection**: GetX (`Get.put`, `Get.find`)
- **Services**: Centralized audio, music fetching, download, equalizer, and backup/restore logic
- **Native integration**: Keep Android-specific JNI bindings and manifest configuration aligned with Dart services

## Development Workflow

### Setup
```bash
flutter pub get
```

### Linting
```bash
flutter analyze
```

### Build
```bash
flutter build apk --release
```

### Tests
```bash
flutter test
```

## Coding Guidelines

1. Follow Dart/Flutter best practices and the configured `flutter_lints` rules.
2. Keep state management in existing GetX controllers and put reusable widgets in `lib/ui/widgets/`.
3. Preserve existing playback, background audio, downloads, search, playlists, albums/artists, settings, QR scanning, equalizer, lyrics, backup/restore, and playback restoration.
4. Keep responsive layouts that improve Android tablet/foldable support. Do not remove width-based layout logic just because it resembles a desktop layout.
5. Hardware keyboard support can be useful on Android; inspect how it is used before removing shortcuts or focus navigation.
6. Use `GetPlatform.isAndroid` only where a genuine Android-specific behavior is required. Do not add desktop platform branches or reintroduce desktop-only packages.
7. Keep Android permissions, Gradle configuration, JNI/JNIGen setup, and native bindings in sync with their Dart callers.
8. Preserve Git-based dependency pins in `pubspec.yaml` unless a change is specifically needed and verified.
9. Icons are located in `assets/icons/`; localization files are in `localization/` and use GetX's `Languages()` translations.

## Important Project Constraints

- Do not modify the YouTube Account/login section unless a blocking issue makes it necessary; explain the reason before touching it.
- Do not modify `test/song_info_dialog_test.dart` unless explicitly authorized.
- Work only on the existing `feature/advanced-equalizer` branch for the current cleanup. Never switch to or modify `main`, and do not create a new branch.
- Do not claim tests or workflows passed without checking their actual results.
- Keep the app Android-only. Do not add Windows, Linux, macOS, iOS, or web build targets/workflows.
- Never remove shared functionality or a dependency solely because it also supports another platform.

## Common Tasks

### Adding a Screen
1. Create the screen in `lib/ui/screens/[ScreenName]/`.
2. Add or update its GetX controller when appropriate.
3. Register dependencies consistently with existing patterns.
4. Add navigation and localization where needed.

### Modifying Audio Playback
- Audio logic: `lib/services/audio_handler.dart`
- Player UI and controller: `lib/ui/player/`
- Equalizer services and native Android bindings: `lib/services/equalizer.dart` and `lib/native_bindings/`
- Keep `lib/services/local_proxy.dart` if required by playback.
- Keep `terminate_restart` initialization because Android playback/session restoration depends on it.

## CI/CD

- Code quality checks run through `.github/workflows/code_quality.yml`.
- Android APK builds run through `.github/workflows/mdlovfi-apk.yml`.
- Android release APK packaging and checksum verification run through `.github/workflows/release.yml`.
- Release publishing is tag-triggered; do not create a release tag or publish a release without explicit authorization.

## Testing

- Tests are in `test/`.
- Run focused tests for changed logic, then the available full test suite.
- Do not weaken or alter protected tests to make CI green.
- Physical-device testing must be reported separately from emulator/CI checks.

## Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [GetX Documentation](https://pub.dev/packages/get)
- [Hive Documentation](https://docs.hivedb.dev/)
- See `README.md` for the current Android feature list and project credits.
