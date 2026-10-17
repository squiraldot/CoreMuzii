# Project Memory / Agent Database

This document records current project architecture and development guidance for MuziiNap.

## Project Context

- **Repository:** `squiraldot/CoreMuzii`
- **App:** MuziiNap / MuziiNap
- **Package:** `mdlovfimusic`
- **Application ID:** `com.merrmist.mdlovfimusic`
- **Platform:** Android-only Flutter application
- **Language:** Dart / Flutter
- **Dart SDK constraint:** `>=3.1.5 <4.0.0`
- **Main development branch for current work:** `feature/advanced-equalizer`

## Development Guidelines

- Keep changes aligned with the Android-only app. Do not restore removed iOS, desktop, or web runner/build targets without an explicit project decision.
- Preserve shared Flutter code and Android plugin implementations; a dependency is not removable merely because it also supports other platforms.
- Before removing a file or dependency, check imports, asset declarations, workflows, native configuration, tests, and documentation references.
- Run `flutter pub get`, `flutter analyze --no-fatal-infos lib test`, and `flutter test --no-pub` when the environment permits. The GitHub Actions workflows are the authoritative remote verification.
- Format changed Dart files with `dart format`.
- Keep release/version information consistent across `pubspec.yaml`, changelog and release notes when preparing a release.

## Current Build and CI

- `.github/workflows/code_quality.yml`: analyzer and Flutter test suite.
- `.github/workflows/muziinap-apk.yml`: Android APK build.
- `.github/workflows/release.yml`: Android release APK packaging and verification.
- Android build outputs belong under generated build directories and must not be committed.

## Project Structure

- `android/`: Android app, manifest, Gradle configuration, Kotlin integration and resources.
- `lib/`: Flutter UI, services, models, native bindings and utilities.
- `test/`: Flutter unit/widget tests.
- `assets/icons/`: app fallback icons declared in `pubspec.yaml`.
- `localization/`: localization sources and generator.
- `fastlane/metadata/android/`: Android store metadata.
- `.github/workflows/`: CI and Android packaging workflows.
- `jnigen.yaml`: JNI binding generation configuration.
- `git-sync.sh`: optional manual local Git/release helper; review its prompts carefully before use because it stages all changes and can replace a remote tag after confirmation.

## Android Architecture

- **State management:** GetX.
- **Persistence:** Hive.
- **Playback/background controls:** `just_audio` and `audio_service`.
- **Networking:** `dio`, HTTP APIs and YouTube-related services.
- **Android native integration:** Kotlin and JNI bindings where configured.
- **Localization:** generated from files in `localization/`.

## Release and Safety Notes

- The release workflows use Flutter and Android build commands directly; there is no root Dockerfile-based custom GitHub Action in this repository.
- Do not treat old cross-platform packaging instructions as current.
- Keep store metadata and historical audit documents unless there is a specific reason to remove them.
