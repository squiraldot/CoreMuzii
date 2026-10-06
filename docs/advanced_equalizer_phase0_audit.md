# Advanced Equalizer — Phase 0 Audit

## Repository state

- Base branch: `main`
- Feature branch: `feature/advanced-equalizer`
- Flutter app with Android/Kotlin native integration.
- `just_audio: ^0.10.6`
- `audio_service: ^0.18.17`
- Existing JNI bindings are generated in `lib/native_bindings/andrid_utils.dart`.

## Existing EQ path

The current flow is:

```
SettingsScreen
  -> PlayerController.openEqualizer()
  -> MyAudioHandler.customAction("openEqualizer")
  -> EqualizerService.openEqualizer(sessionId)
  -> JNI Equalizer.openEqualizer(...)
  -> Android ACTION_DISPLAY_AUDIO_EFFECT_CONTROL_PANEL
```

The existing implementation therefore launches a system/manufacturer EQ UI. It is not an in-app DSP engine.

The audio session is obtained from:

```dart
_player.androidAudioSessionIdStream
```

and the current handler sends Android audio-effect open/close session intents.

## Important native mismatch

The current Kotlin file declares:

```kotlin
package com.merrmist.mdlovfimusicmusic
```

while the generated JNI binding expects:

```
com.merrmist.mdlovfimusic.Equalizer
```

and `MainActivity.kt` uses `com.merrmist.mdlovfimusic`.

This package mismatch must be corrected as part of the native EQ replacement; otherwise the generated binding and native class do not describe the same JVM class.

## DSP insertion point

For the current player architecture, the stable Android integration point is the player's Android audio-session ID. Android's `AudioEffect` API explicitly supports attaching insert effects to a specific AudioTrack/MediaPlayer session.

Android API 28+ also provides `DynamicsProcessing`, which exposes configurable multi-band EQ, compressor and limiter stages. It can be attached to the same audio session and controlled in realtime.

This gives Phase 1 a practical Android backend without rewriting the whole `just_audio` player.

## Limitation discovered

`DynamicsProcessing.EqBand` models bands using cutoff frequency + gain; it does not expose the same Q parameter as the platform-independent MDLovFi model. Therefore:

- Phase 1 graphic EQ can use Android `DynamicsProcessing` as the first Android backend.
- Parametric EQ (Phase 4) should not pretend that the Android effect is a full parametric implementation.
- A future raw-PCM backend may need an ExoPlayer/Media3 `AudioProcessor` integration or another dedicated DSP path to provide exact biquad/Q semantics.

The current `just_audio` package is built on Media3/ExoPlayer on Android, and Media3 supports custom `AudioProcessor` chains for PCM playback. That route should be evaluated before Phase 4 rather than prematurely forking the player now.

## Lifecycle findings

The player can be recreated/reconfigured through `setAudioSource` and the audio session ID can change. The current listener only sends the generic audio-effect session-open intent when a session ID appears.

The replacement backend therefore needs explicit:

- session attach/detach
- state re-application after session ID changes
- safe disposal
- fallback to unprocessed playback when an effect cannot be created

## Constraints

Do not change:

- package/application ID
- YouTube authentication
- CI/workflow behavior
- unrelated playback architecture

Prefer:

- existing Hive persistence for Phase 2
- a platform-independent EQ model
- a backend interface
- Android-specific DSP implementation behind that interface
- no GPL code copied from third-party EQ implementations

## Phase 0 exit status

Audit complete. No production playback behavior was intentionally changed by the audit.

Next implementation boundary:

1. keep the new EQ model independent of Flutter widgets;
2. complete the Android backend/session lifecycle;
3. wire a real in-app 10-band graphic UI;
4. then add persistence/presets.
