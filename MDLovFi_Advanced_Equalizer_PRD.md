# MDLovFi Advanced Equalizer — PRD

**Repository:** `squiraldot/CoreMuzii`  
**Feature:** Advanced in-app Equalizer, Presets, Import/Export, AutoEQ and Telegram ecosystem  
**Status:** Planning / implementation-ready  
**Important:** This PRD must be implemented on a new feature branch. `main` must not be modified directly.

---

## 1. Product Vision

Build a professional, self-contained audio EQ inside MDLovFi instead of relying on the Android/system Equalizer panel.

The final system should provide:

- In-app graphic EQ
- Parametric EQ
- Preamp
- Built-in presets
- User-created presets
- Local persistence
- Import/export of portable `.mdleq` preset files
- Limiter/clipping protection
- Bass boost, loudness, compressor and stereo controls
- Spectrum analyzer
- AutoEQ/headphone profiles
- Optional Telegram preset sharing and community ecosystem

The EQ engine and preset format must be designed first so later features do not require a rewrite.

---

# 2. Mandatory Git Workflow

## Never develop directly on `main`

At the start:

```bash
git checkout main
git pull
git checkout -b feature/advanced-equalizer
```

All EQ work must happen on that branch.

Recommended branch:

```text
feature/advanced-equalizer
```

Do not:

- commit EQ work to `main`
- force-push `main`
- rewrite unrelated commits
- change package ID
- change YouTube authentication
- change CI/workflow behavior unless explicitly requested
- delete existing EQ code before the replacement is verified

## Final workflow

```text
main
  ↓
feature/advanced-equalizer
  ↓
Phase 0 → Phase 1 → Phase 2 → ... → Phase 8
  ↓
Tests + analysis + Android build + real-device QA
  ↓
Push branch
  ↓
Pull Request → main
  ↓
CI + review
  ↓
Merge only after everything passes
```

The AI must not merge incomplete work into `main`.

---

# 3. Current Repository Context

Before coding, inspect the actual current repository.

Known architecture:

- Flutter
- Android/Kotlin native integration
- `just_audio`
- `audio_service`
- Hive/local persistence
- Android audio-session handling
- existing native `Equalizer.kt`
- generated JNI bindings

The current native Equalizer is primarily an Android/system EQ launcher. It is not the final in-app DSP system.

Do not assume file paths or APIs are unchanged. Audit them first.

---

# 4. Technical Direction

Preferred architecture:

```text
Flutter UI
    ↓
EQ Domain Model
    ↓
EQ Controller / State
    ↓
DSP Abstraction
    ↓
Android DSP Backend
    ↓
just_audio / audio pipeline
    ↓
Audio Output
```

UI must not directly call Android audio APIs.

The DSP backend should be isolated behind an abstraction so desktop/future platforms can have their own implementation.

Use existing playback infrastructure wherever practical. Do not rewrite the entire player just to add EQ.

Research references that may be studied for architecture:

- Android `Equalizer`
- Android `DynamicsProcessing`
- `just_audio` audio effects/pipeline
- SimpMusic custom `EqualizerAudioProcessor`
- Metrolist custom EQ/audio processor
- AutoEQ
- Equalizer314

Do not copy GPL implementation code into MDLovFi without an explicit licensing review. Prefer independent implementation based on documented algorithms/APIs.

---

# 5. Core EQ Model

Create a platform-independent model.

Each EQ band should contain:

```text
id
type
frequency
gainDb
q
enabled
```

Filter types:

```text
Peaking
Low Shelf
High Shelf
Low Pass
High Pass
Band Pass
Notch
```

Global state:

```text
enabled
preampDb
limiterEnabled
outputGainDb
```

Future DSP fields may include:

```text
bassBoost
loudness
compressor
stereoWidth
crossfeed
reverb
```

The UI must never own the storage schema.

---

# 6. Phase Roadmap

## Phase 0 — Repository Audit / Technical Spike

### Goal

Understand the current audio pipeline before changing production behavior.

### Tasks

- inspect `just_audio` player creation
- inspect `AudioHandler`
- inspect audio session code
- inspect existing `Equalizer.kt`
- inspect JNI bridge
- find every EQ caller
- identify track/player recreation paths
- identify crossfade/preload paths
- identify correct DSP insertion point
- confirm Android SDK/min SDK
- verify supported audio formats

### Deliverable

Document:

- DSP insertion point
- reusable existing components
- components to replace
- Android limitations
- fallback behavior

### Exit criteria

No production behavior is changed in Phase 0.

---

# Phase 1 — Core 10-Band Graphic EQ

### Goal

Create a reliable realtime EQ foundation.

Bands:

```text
31 Hz
62 Hz
125 Hz
250 Hz
500 Hz
1 kHz
2 kHz
4 kHz
8 kHz
16 kHz
```

Gain:

```text
-15 dB … +15 dB
```

Features:

- enable/disable
- preamp
- reset/flat
- bypass
- draggable EQ curve
- accessible sliders/numeric controls
- realtime application

Use stable biquad/audio-EQ mathematics, preferably the Audio EQ Cookbook approach.

### Acceptance

- flat EQ is effectively transparent
- boosts/cuts work correctly
- no obvious clipping by default
- survives track changes
- survives player recreation
- survives restart
- no playback crash

---

# Phase 2 — Built-in + Custom Presets

### Built-in presets

Ship curated presets such as:

```text
Flat
Bass Boost
Deep Bass
Vocal
Pop
Rock
Jazz
Classical
Acoustic
EDM
Hip-Hop
Metal
Podcast
Warm
Bright
Night
Cinematic
Loud
```

Presets must be intentionally tuned, not random gain values.

### Custom presets

Users can:

- save
- rename
- update
- duplicate
- delete
- apply
- favorite/pin if practical

Built-in presets must be immutable.

Editing a built-in preset should create/save a custom copy.

### Storage

Use existing Hive/local persistence rather than introducing another database without a strong reason.

### Acceptance

- all built-ins work offline
- custom presets survive restart
- built-ins cannot be accidentally destroyed
- applying preset updates audio immediately

---

# Phase 3 — Portable Preset Format

Use:

```text
.mdleq
```

Recommended JSON structure:

```json
{
  "format": "mdlovfi-eq",
  "version": 1,
  "name": "My Bass",
  "author": "User",
  "enabled": true,
  "preamp": -3.0,
  "bands": [
    {
      "type": "peaking",
      "frequency": 60.0,
      "gainDb": 5.0,
      "q": 1.2,
      "enabled": true
    }
  ]
}
```

Requirements:

- export preset
- import preset
- schema validation
- versioning
- malformed-file protection
- safe numeric ranges
- preview before applying
- future-version compatibility strategy

The format must be platform-independent.

---

# Phase 4 — Parametric EQ

### Goal

Provide professional EQ control.

Users can:

- add band
- delete band
- enable/disable band
- change frequency
- change gain
- change Q
- choose filter type

Supported filters:

```text
Peaking
Low Shelf
High Shelf
Low Pass
High Pass
Band Pass
Notch
```

Recommended initial limit:

```text
10–12 active bands
```

Graphic and parametric modes must operate on the same underlying EQ model.

Switching modes must not silently destroy settings.

---

# Phase 5 — Advanced DSP

Implement incrementally.

## Bass Boost

Controls:

- amount
- frequency
- Q

## Loudness

Must correctly interact with:

- EQ
- preamp
- limiter

## Compressor

Controls:

```text
threshold
ratio
attack
release
knee
makeup gain
```

## Limiter

Controls:

```text
enabled
ceiling
release
```

It must protect against clipping caused by EQ/bass/loudness/compressor gain.

## Stereo

Potential:

```text
balance
mono
stereo width
channel swap
```

Only ship features that work correctly on the target pipeline.

## Crossfeed

Optional headphone feature.

## Reverb / spatial effects

Optional. Do not ship poor-quality effects merely for feature count.

Every effect should be independently bypassable.

---

# Phase 6 — Spectrum Analyzer

### Goal

Provide realtime visual feedback.

Features:

- FFT spectrum
- frequency scale
- amplitude scale
- EQ curve overlay
- draggable EQ points
- optional peak hold
- optional smoothing

Modes:

```text
Spectrum
EQ Curve
Spectrum + EQ Curve
```

Analyzer work must not block the audio thread or cause UI jank.

---

# Phase 7 — AutoEQ / Headphone Profiles

### Goal

Support measurement-based headphone/IEM correction.

Flow:

```text
Headphone EQ
 ↓
Search
 ↓
Select model
 ↓
Preview curve
 ↓
Apply
 ↓
Save as preset
```

Features:

- search headphone/IEM
- profile preview
- apply profile
- save as custom preset
- export as `.mdleq`

Use AutoEQ data/algorithms appropriately. Do not copy GPL implementation code into the app without licensing review.

---

# Phase 8 — Telegram Preset Ecosystem

Telegram is an optional sharing layer, not a dependency of the EQ engine.

## First version

```text
Preset
 ↓
Export .mdleq
 ↓
Android Share
 ↓
Telegram
```

## Future bot

Bot can:

```text
receive .mdleq
validate
store
assign ID
return preset
search presets
```

Possible commands:

```text
/search bass
/search vocal
/search sony
/get <preset-id>
```

Keep Telegram/backend logic separate from the EQ engine.

---

# 7. Preset Architecture

Recommended model:

```text
Preset
├── metadata
│   ├── id
│   ├── name
│   ├── author
│   ├── description
│   ├── createdAt
│   └── updatedAt
│
├── EQ
│   ├── enabled
│   ├── preamp
│   └── bands[]
│
├── DSP
│   ├── limiter
│   ├── compressor
│   ├── bassBoost
│   ├── loudness
│   ├── stereo
│   └── effects
│
└── formatVersion
```

Keep metadata separate from DSP parameters.

---

# 8. Audio Safety

Critical requirements:

- safe default preamp
- clipping protection
- stable filter coefficients
- no NaN/Infinity propagation
- constrain extreme values
- safe reset/bypass
- unsupported formats fail gracefully
- DSP errors must not crash playback
- when possible, failed DSP should fall back to normal playback

---

# 9. Player Lifecycle

EQ must remain correct across:

```text
play
pause
resume
seek
skip
queue changes
track changes
player recreation
background playback
crossfade/preload
```

If multiple players/processors exist, every relevant player must receive the correct EQ state.

Do not assume one permanent player instance.

---

# 10. UI

Suggested structure:

```text
MDLovFi Equalizer

[ ON / OFF ]

Current Preset
┌─────────────────────┐
│ Bass Boost       ▼  │
└─────────────────────┘

[ Graphic ] [ Parametric ]

        EQ GRAPH

31  62  125  250 ... 16K

Preamp
────────●────────

Advanced
├─ Bass Boost
├─ Loudness
├─ Compressor
├─ Limiter
├─ Stereo
└─ Effects

Presets
├─ Built-in
└─ My Presets

[Save] [Import] [Export] [Share]
```

Design should follow MDLovFi's existing UI language.

Do not make drag gestures the only way to edit bands; provide sliders/numeric controls for accessibility and precision.

---

# 11. Testing

## Unit tests

Cover:

- EQ model serialization
- preset serialization
- validation
- migration
- filter coefficient calculations
- gain limits
- Q limits
- preset equality
- built-in preset integrity

## Controller tests

Cover:

- apply preset
- edit band
- reset
- bypass
- persistence
- import/export
- switching presets

## Integration tests

Cover:

- player + EQ
- track change
- player recreation
- background playback
- audio-session lifecycle

## Regression

Existing features must continue working:

- playback
- queue
- YouTube playback
- YouTube login/session
- library
- settings
- background playback
- media controls

---

# 12. Manual QA

Before the final PR:

### EQ

- [ ] Open EQ
- [ ] Enable/disable
- [ ] Flat
- [ ] Bass boost
- [ ] Treble boost
- [ ] Negative gain
- [ ] Preamp
- [ ] Reset
- [ ] Bypass

### Presets

- [ ] Built-ins
- [ ] Save custom
- [ ] Rename
- [ ] Edit
- [ ] Delete
- [ ] Restart persistence
- [ ] Immediate apply

### Files

- [ ] Export `.mdleq`
- [ ] Import `.mdleq`
- [ ] Invalid file handling
- [ ] Preview imported preset
- [ ] Apply imported preset

### Playback

- [ ] YouTube/network playback
- [ ] track change
- [ ] seek
- [ ] queue
- [ ] pause/resume
- [ ] background playback
- [ ] long session

### Performance

- [ ] no obvious crackling
- [ ] no playback interruption
- [ ] no UI freezing
- [ ] no excessive memory growth
- [ ] acceptable CPU/battery usage

---

# 13. Definition of Done

The project is complete only when:

- [ ] Phase 0 audit completed
- [ ] Core EQ works on real Android playback
- [ ] Graphic EQ works
- [ ] Built-in presets work
- [ ] Custom presets persist
- [ ] `.mdleq` import/export works
- [ ] Parametric EQ works
- [ ] Limiter/clipping protection works
- [ ] Advanced DSP features marked for release work
- [ ] Spectrum analyzer works if Phase 6 ships
- [ ] AutoEQ works if Phase 7 ships
- [ ] Telegram sharing works if Phase 8 ships
- [ ] Unit/integration tests pass
- [ ] static analysis passes
- [ ] Android build succeeds
- [ ] APK is generated
- [ ] real-device QA passes
- [ ] existing playback remains stable
- [ ] YouTube functionality remains stable
- [ ] no unrelated regressions
- [ ] feature branch pushed
- [ ] PR opened against `main`
- [ ] CI passes
- [ ] review completed
- [ ] only then merge into `main`

---

# 14. AI Coding-Agent Instructions

When this PRD is given to an AI:

### Before coding

1. Inspect repository.
2. Check current `main`.
3. Check `git status`.
4. Pull latest `main`.
5. Create a new feature branch.
6. Inspect the existing player/audio architecture.
7. Inspect current EQ code.
8. Check dependency versions.
9. Decide the DSP insertion point based on the actual code, not assumptions.

### During coding

- Work only on the feature branch.
- Prefer existing dependencies.
- Avoid unnecessary rewrites.
- Keep DSP behind an abstraction.
- Add tests with each phase.
- Keep commits small and logical.
- Do not alter CI unexpectedly.
- Do not alter YouTube auth.
- Do not alter package ID.
- Do not touch unrelated features.

### Verification rule

Never claim:

```text
tests passed
build passed
APK generated
CI passed
```

unless the action was actually executed and verified.

If Flutter/Android tooling is unavailable, explicitly report the limitation.

### Final handoff

After all phases:

```text
git status
git diff main...HEAD
run tests
run analysis
build APK
perform real-device QA
push feature branch
open PR to main
wait for CI/review
merge only after approval
```

---

# 15. Recommended Commit Sequence

Example:

```text
feat(eq): add EQ domain model
feat(eq): add Android DSP backend
feat(eq): add 10-band graphic EQ
test(eq): add core EQ tests
feat(eq): add built-in presets
feat(eq): add custom preset persistence
feat(eq): add mdleq import export
feat(eq): add parametric EQ
feat(eq): add advanced DSP controls
feat(eq): add spectrum analyzer
feat(eq): add AutoEQ profiles
feat(eq): add Telegram preset sharing
test(eq): add end-to-end EQ coverage
fix(eq): resolve playback lifecycle issues
```

Exact commits may differ after repository audit.

---

# 16. Final Product Architecture

```text
                    MDLovFi EQ
                        │
          ┌─────────────┴─────────────┐
          │                           │
      EQ Model                    Preset Manager
          │                           │
    ┌─────┴─────┐              ┌─────┴──────┐
    │           │              │            │
 Graphic    Parametric      Built-in      User
    │           │              │            │
    └─────┬─────┘              └─────┬──────┘
          │                           │
          └────────────┬──────────────┘
                       │
                 DSP Controller
                       │
              ┌────────┴────────┐
              │                 │
           Android           Future Desktop
              │
        just_audio pipeline
              │
          Audio Output
```

The core principle:

**Build the DSP engine + EQ model + preset format correctly first. UI, AutoEQ, Telegram and community presets must build on top of that stable foundation.**
