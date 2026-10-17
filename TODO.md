# TODO / Feature Audit

**Audit branch:** `feature/advanced-equalizer`  
**Audit basis:** Current source files on this branch, existing CI results, and the user's Android-device smoke-test confirmation.  
**Status key:** `Complete/Passed` means implementation is present in source or the relevant verification passed. `Partial` / `In Progress` means the broader item still needs follow-up; it is not being marked complete based on file existence alone.

## Screens and housekeeping

- [Complete/Passed] <s>Fix PlayerPane and add controller</s>
- [Complete/Passed] <s>Fix & complete Playlist pane</s>
- [Complete/Passed] <s>Album Screen</s>
- [Complete/Passed] <s>Playlist screen for items</s>
- [Partial] Search screen — search UI/controller and history/suggestions exist; remaining polish/behavior needs a focused review.
- [Complete/Passed] <s>Search result screen</s>
- [Complete/Passed] <s>Artist Screen</s>
- [Partial] App Settings — settings screen/controller are implemented; remaining settings work needs a focused review.
- [Complete/Passed] <s>Android-only housekeeping / desktop-specific cleanup</s> — see [Android Cleanup Verification](ANDROID_CLEANUP_VERIFICATION.md).
- [Complete/Passed] <s>Battery optimization disable option</s> — Android settings UI and permission-request handler are present.
- [Partial] Album/Playlist screen enhancements — album library/bookmark handling is implemented; additional playlist/album details and full UX scope still need review.

## Playlist and offline features

- [Complete/Passed] <s>Favourite playlist</s> — the built-in favourites playlist and library handling are present.
- [In Progress] Offline playback / downloads
  - [Complete/Passed] <s>Song cache implementation</s>
  - [In Progress] Song and image expiry/cleanup — housekeeping exists, but complete expiry behavior has not been fully verified.
- [Complete/Passed] <s>Theme based on thumbnail</s>
- [Complete/Passed] <s>Background playing</s>
- [Complete/Passed] <s>Notification controls</s>
- [Complete/Passed] <s>Local playlist management basics (create, add songs, rename, remove)</s>

## UI

- [Partial] Shimmer effect on loading — shimmer widgets exist; coverage across every relevant loading state has not been verified.

## Fix required / maintenance

- [Complete/Passed] <s>Pushing song to playlist</s>
- [Pending] Code refactor — broad task; no blanket completion claim made.

## Priority work

- [Complete/Passed] <s>Playlist remove & rename feature</s>
- [Complete/Passed] <s>Enqueue Song fix</s>
- [Complete/Passed] <s>Go to Album & View Artist fix</s>
- [Complete/Passed] <s>Empty Playlist representation</s>
- [Complete/Passed] <s>Search header fix</s>
- [Complete/Passed] <s>Search artist list</s>

## Verification notes

- Latest verified cleanup CI run: [Code Quality](https://github.com/squiraldot/CoreMuzii/actions/runs/39014590929) — success, 61 tests passed.
- Android APK build/signing: [MDLovFi APK workflow](https://github.com/squiraldot/CoreMuzii/actions/runs/39014590927) — success.
- Release APK packaging/checksums: [Android Release workflow](https://github.com/squiraldot/CoreMuzii/actions/runs/39014590930) — success. The GitHub Release publication job was skipped as expected for a branch-push run without a version tag.
- Device smoke test: user confirmed installation, launch, and app functionality on their Android phone.
- Items labelled Partial/In Progress/Pending were intentionally not marked Complete/Passed without stronger evidence.
