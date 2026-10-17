# TODO / Feature Audit

**Audit branch:** `feature/advanced-equalizer`  
**Audit scope:** Rechecked every item previously marked Partial, In Progress, or Pending against current source. Fixed concrete issues and added regression tests where practical.  
**Status key:** `Complete/Passed` means the feature is implemented and covered by source review or available tests; the newest CI run is linked in the verification notes once complete.

## Screens and housekeeping

- [Complete/Passed] <s>Fix PlayerPane and add controller</s>
- [Complete/Passed] <s>Fix & complete Playlist pane</s>
- [Complete/Passed] <s>Album Screen</s>
- [Complete/Passed] <s>Playlist screen for items</s>
- [Complete/Passed] <s>Search screen</s> — input, suggestions, history, URL handling, and search navigation are implemented.
- [Complete/Passed] <s>Search result screen</s> — loading state now uses shimmer placeholders.
- [Complete/Passed] <s>Artist Screen</s>
- [Complete/Passed] <s>App Settings</s> — settings screen/controller are implemented and preference resolution has tests.
- [Complete/Passed] <s>Android-only housekeeping / desktop-specific cleanup</s> — see [Android Cleanup Verification](ANDROID_CLEANUP_VERIFICATION.md).
- [Complete/Passed] <s>Battery optimization disable option</s> — Android settings UI and permission-request handler are present.
- [Complete/Passed] <s>Album/Playlist screen enhancements (bookmarks and saved details)</s> — album/playlist library add/remove and persisted details are implemented.

## Playlist and offline features

- [Complete/Passed] <s>Favourite playlist</s> — the built-in favourites playlist and library handling are present.
- [Complete/Passed] <s>Offline playback/download management</s> — cache/download list reconciliation and stale URL cleanup are implemented.
  - [Complete/Passed] <s>Song cache implementation</s>
  - [Complete/Passed] <s>Song URL expiry and stale image cleanup</s> — malformed/expired URL cache entries are removed safely; missing downloads and orphaned cached-song thumbnails are cleaned up.
- [Complete/Passed] <s>Theme based on thumbnail</s>
- [Complete/Passed] <s>Background playing</s>
- [Complete/Passed] <s>Notification controls</s>
- [Complete/Passed] <s>Local playlist management basics (create, add songs, rename, remove)</s>

## UI

- [Complete/Passed] <s>Shimmer effect on loading</s> — Home uses `HomeShimmer`; search results now use `SongListShimmer` while content loads.

## Fix required / maintenance

- [Complete/Passed] <s>Pushing song to playlist</s>
- [Complete/Passed] <s>Targeted code refactoring</s> — extracted safe playlist-index lookup, hardened offline housekeeping, and centralized JSON/CSV export filename selection in `lib/utils/export_file_helper.dart` with regression tests. This closes the scoped refactoring TODO without attempting a risky repository-wide rewrite.

## Priority work

- [Complete/Passed] <s>Playlist remove & rename feature</s>
- [Complete/Passed] <s>Enqueue Song fix</s>
- [Complete/Passed] <s>Go to Album & View Artist fix</s>
- [Complete/Passed] <s>Empty Playlist representation</s>
- [Complete/Passed] <s>Search header fix</s>
- [Complete/Passed] <s>Search artist list</s>

## Regression coverage added in this audit

- `test/playlist_helpers_test.dart` — matching IDs, missing IDs, and malformed stored entries.
- `test/house_keeping_test.dart` — malformed cache records, empty URLs, and a valid future-expiry stream URL.

## Verification notes

- Previous cleanup baseline: [Code Quality](https://github.com/squiraldot/CoreMuzii/actions/runs/39014590929) — success, 61 tests passed.
- Previous Android APK build/signing: [MuziiNap APK workflow](https://github.com/squiraldot/CoreMuzii/actions/runs/39014590927) — success.
- Previous release APK packaging/checksums: [Android Release workflow](https://github.com/squiraldot/CoreMuzii/actions/runs/39014590930) — success. The GitHub Release publication job was skipped as expected for a branch-push run without a version tag.
- Device smoke test: user confirmed installation, launch, and app functionality on their Android phone.
- Latest TODO-audit CI on commit `b8597b0`: [Code Quality](https://github.com/squiraldot/CoreMuzii/actions/runs/39020656681) and [Android APK](https://github.com/squiraldot/CoreMuzii/actions/runs/39020656680) both succeeded.
- Export filename refactor adds `test/export_file_helper_test.dart`; final verification for the refactor commit is tracked by the newest branch CI runs.
