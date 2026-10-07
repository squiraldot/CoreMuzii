# MDLovFi Advanced Equalizer — PRD

**Repository:** `squiraldot/CoreMuzii`  
**Feature:** Advanced in-app Equalizer, Presets, Import/Export, AutoEQ and Telegram ecosystem  
**Status:** Phases 0–4 implemented; Phases 5–8 remaining  
**Important:** Continue implementation on the existing canonical branch `feature/advanced-equalizer`. Do not create additional feature branches. `main` must not be modified directly.

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

All remaining EQ work must continue on the existing branch:

```text
feature/advanced-equalizer
```

Do not create another branch for individual phases. All EQ work must happen on the canonical feature branch.

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
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7 → Phase 8
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

## Current status

| Phase | Status | What is included |
|---|---|---|
| Phase 0 | ✅ Done | Repository/audio pipeline audit and DSP insertion-point decision |
| Phase 1 | ✅ Done | 10-band graphic EQ, realtime Android DSP, preamp, limiter, persistence |
| Phase 2 | ✅ Done | Built-in + custom presets, Hive persistence, preset management |
| Phase 3 | ✅ Done | Portable `.mdleq` import/export, validation, preview |
| Phase 4 | ✅ Done | Parametric EQ with 7 filter types, up to 12 bands, lifecycle/playback fixes |
| Phase 5 | ⏳ Next | Advanced DSP + MDLovFi SoundFX / DSFX-style engine |
| Phase 6 | ⏳ Planned | Realtime spectrum analyzer + EQ curve visualization |
| Phase 7 | ⏳ Planned | AutoEQ / headphone & IEM profiles |
| Phase 8 | ⏳ Planned | Telegram preset sharing + optional community ecosystem |

**Remaining:** 4 phases — Phase 5, 6, 7 and 8.

---

## Phase 0 — Repository Audit / Technical Spike

### Status: ✅ Complete

Completed:

- inspected `just_audio`, `AudioHandler`, audio-session lifecycle and existing Android EQ path
- identified the in-app DSP insertion point
- documented Android `DynamicsProcessing` limitations
- isolated native DSP behind the Flutter service/controller layer
- verified audio-session recreation/lifecycle behavior

---

# Phase 1 — Core 10-Band Graphic EQ

### Status: ✅ Complete

Completed:

- 31 Hz … 16 kHz 10-band graphic EQ
- ±15 dB gain range
- realtime Android DSP application
- preamp and limiter
- draggable curve + numeric gain editing
- persistent EQ configuration
- bypass/reset
- playback lifecycle integration
- unit tests and Android CI verification

---

# Phase 2 — Built-in + Custom Presets

### Status: ✅ Complete

Completed:

- curated built-in presets
- custom save/rename/update/duplicate/delete
- Hive persistence
- immutable built-ins
- preset matching without unnecessary duplicates
- realtime preset application
- preset store tests

---

# Phase 3 — Portable Preset Format

### Status: ✅ Complete

Portable format:

```text
.mdleq
```

Completed:

- versioned JSON schema
- export/import
- validation and safe numeric ranges
- malformed/future-version protection
- import preview before applying
- imported presets remain unsaved until the user chooses Save as
- Android picker compatibility: use a broad native file picker filter and validate `.mdleq` in-app
- codec tests

---

# Phase 4 — Parametric EQ

### Status: ✅ Complete

Completed:

- Graphic / Parametric mode switch
- up to 12 parametric bands
- add/delete bands
- enable/disable bands
- frequency, gain and Q editing
- filter types: Peaking, Low Shelf, High Shelf, Low Pass, High Pass, Band Pass, Notch
- shared underlying EQ model so switching modes does not wipe configuration
- playback/loading regression fixes so EQ application does not block initial playback
- buffer/startup tuning verified on real device
- tests + Android CI verification

Known refinement to address when touching the UI later:

- ensure Graphic mode cannot expose invalid fixed-band assumptions if a configuration contains only custom parametric bands; switching modes must remain safe and predictable.

---

# Phase 5 — Advanced DSP + MDLovFi SoundFX

### Status: ⏳ Next

This phase is the main remaining DSP-engine phase. It should be implemented incrementally and safely. **Do not claim to reproduce any proprietary third-party DSFX implementation.** Build an independent MDLovFi DSP engine inspired by publicly described sound-enhancement controls.

## Phase 5A — Core Advanced DSP

Implement:

### Bass Boost

Controls:

- amount
- frequency
- Q
- bypass

### Loudness

Implement loudness compensation that interacts correctly with:

- EQ gain
- preamp
- output gain
- limiter

### Compressor

Controls:

```threshold
ratio
attack
release
knee
makeup gain
bypass
```

### Limiter / Clipping Protection

Controls:

``
enabled
ceiling
release
bypass
```

Requirements:

- protect against EQ/bass/loudness/compressor gain
- avoid unnecessary pumping
- fail safely without interrupting playback

### Stereo Processing

Controls:

``
balance
mono
stereo width
channel swap
bypass
```

### Crossfeed

Optional headphone feature. Ship only if the implementation is audibly and technically reliable.

### Reverb / Spatial

Optional. Do not ship weak or artificial-sounding processing just to increase feature count.

---

## Phase 5B — MDLovFi SoundFX / DSFX-style Engine

Build a dedicated sound-enhancement layer on top of the stable EQ/DSP pipeline.

Target controls:

``
XBass
XTreble
PowerBass
Output Gain
Dynamic Bass
Stereo / Surround enhancement
Headphone / IEM profile
```

### Design goals

- stronger perceived bass without uncontrolled clipping
- treble enhancement without harshness
- bass punch/body control separate from normal EQ
- output gain compensation
- stereo expansion that does not destroy mono compatibility
- optional headphone/IEM-specific tuning
- every enhancement independently bypassable
- safe automatic gain compensation
- interaction with EQ + compressor + limiter must be deterministic

### Important distinction

The original/proprietary implementation referred to publicly as **DSFX** is not being copied. MDLovFi will implement its own independent DSP chain and should brand it as **MDLovFi SoundFX** (or **MDLovFi DSFX-style**) unless a licensing/specification review establishes otherwise.

---

## Phase 5C — DSP Safety + Integration

Before Phase 5 is considered complete:

- define deterministic DSP processing order
- prevent NaN/Infinity propagation
- constrain all user parameters
- implement clipping/headroom protection
- verify EQ + SoundFX + compressor + limiter interaction
- ensure every effect has a true bypass
- preserve normal playback when DSP initialization fails
- verify audio-session/player recreation
- measure CPU and battery impact
- verify no crackling, dropouts or startup delays
- update `.mdleq` schema/version when new DSP parameters become portable
- migrate old presets safely when new fields are introduced

Recommended processing order to validate experimentally rather than assume:

``
Input
 ↓
Preamp / Headroom
 ↓
Parametric or Graphic EQ
 ↓
SoundFX / Bass / Treble / Loudness
 ↓
Compressor
 ↓
Stereo processing
 ↓
Limiter / Clipping protection
 ↓
Output Gain
 ↓
Audio Output
```

The exact order must be finalized from measured/audible behavior and platform constraints.

---

# Phase 6 — Spectrum Analyzer

### Status: ⏳ Planned

### Goal

Provide realtime visual feedback without blocking audio processing.

Implement:

- FFT spectrum
- frequency scale
- amplitude scale
- EQ curve overlay
- draggable EQ points where practical
- optional peak hold
- optional smoothing
- Spectrum / EQ Curve / Spectrum + EQ Curve modes

Requirements:

- analyzer work stays off the audio-critical path
- no UI jank during playback
- configurable update rate if needed for battery/CPU
- visualize the same effective EQ/SoundFX curve where technically meaningful

---

# Phase 7 — AutoEQ / Headphone Profiles

### Status: ⏳ Planned

Flow:

``
Headphone / IEM EQ
 ↓
Search
 ↓
Select model
 ↓
Preview correction curve
 ↓
Apply
 ↓
Save as preset
 ↓
Export .mdleq
```

Implement:

- headphone/IEM search
- model/profile metadata
- profile preview
- apply correction
- safe gain/headroom handling
- save as custom preset
- export as `.mdleq`
- clear handling when no profile is available

Use AutoEQ data/algorithms appropriately. Do not copy GPL implementation code without licensing review.

Potential future enhancement:

- user-owned custom measurement import
- target curve selection
- profile normalization/headroom controls

---

# Phase 8 — Telegram Preset Ecosystem

### Status: ⏳ Planned

Telegram remains an optional sharing layer, never a dependency of the DSP engine.

## Phase 8A — Local Sharing

First ship:

``
Preset
 ↓
Export .mdleq
 ↓
Android Share
 ↓
Telegram / any compatible app
```

Requirements:

- share exported `.mdleq` directly from MDLovFi
- preserve filename and metadata
- handle share cancellation/failure safely

## Phase 8B — Optional Telegram Bot

Future bot can:

``
receive .mdleq
validate
store
assign ID
return preset
search presets
```

Possible commands:

``
/search bass
/search vocal
/search sony
/get <preset-id>
```

Keep Telegram/backend logic separate from the EQ engine and app playback core.

## Phase 8C — Community Safety

If a public preset ecosystem is shipped:

- validate schema server-side
- reject malformed/unsafe parameter values
- version presets
- keep attribution metadata
- allow moderation/takedown
- never execute arbitrary code from a preset

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
