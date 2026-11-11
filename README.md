<!-- coderabbit-ai-generated:v1 -->

<!-- coderabbit-ai-generated-section:v1:593c0bd5644ff6476c0a9a2793ea2cd7e0af5dc34cb45aa918dbf3fd289f61c4 -->

# Dream Reader

An independently branded, local-first manga reader for Android, built with Flutter and a Kotlin source engine.

**Application ID:** `com.dreamreader.app` · **Device target:** ARM64 · **Minimum Android:** 8.0 (API 26)

## The reading experience

- Five primary spaces: Home, Library, Browse, Updates and Downloads.
- Dream Dark, Midnight OLED, Aurora, Pure Light and custom accent themes, with Manrope and Newsreader typography.
- Reorderable home sections, continue reading, source-provided popular titles, library-based recommendations and reading statistics.
- Grid, compact and list libraries, categories, combined filters, unread badges, sorting and batch actions.
- Webtoon, long-strip, vertical, LTR, RTL and double-page readers; progress, bookmarks, brightness, orientation, volume navigation and prefetching.
- Chapter downloads with WorkManager, retry, page-level resume, queue controls and offline reading.
- Integrity-checked backups, merge previews, scheduled backups to an Android-selected folder and compatible Mihon protobuf import.

## Source architecture

Keiyoushi is offered on first launch, with disclosure and a switch to decline it. Catalogues are fetched live, using the current gzip/protobuf format. Nothing is bundled as a fabricated manga or extension catalogue.

Source APKs are downloaded privately after explicit consent. Android package metadata and APK cryptographic signatures are verified against the selected repository signer. The compatibility module exports current Mihon source API interfaces (1.4 and 1.6) and dependencies. Source browsing, filters, preferences, metadata, chapters and image requests execute in a dedicated Android process. Image retrieval uses the source's HTTP client so extension interceptors are retained.

**The extension process shares the app UID. It is not a security sandbox.** Extensions can access the app's network and private storage. Install only code you trust. Interactive website verification uses a shared-cookie WebView and requires the user's participation.

Read [architecture](docs/architecture.md), [development and signing](docs/development.md), and [verification status](docs/verification.md). An implemented API adapter is not proof that every third-party extension works; release notes identify tested versions and remaining limitations.

## Build

Use Flutter 3.47.9 / Dart 3.13.7, JDK 21, Android SDK 37.0 and the repository's Gradle wrapper. Dependencies are locked in `pubspec.lock`. Configure a private signing-properties file outside the checkout, then run:

```sh
export DREAM_READER_SIGNING_PROPERTIES=/private/path/signing.properties
export ANDROID_HOME=/path/to/android/sdk
scripts/build_release.sh
```

The script runs analysis, unit/widget tests, builds a signed ARM64 release and independently checks ZIP integrity, architecture, package ID, non-debuggable status, signature and ZIP alignment. Outputs are in `build/release/`. Device journeys are separate; static checks do not establish runtime compatibility.

## Automation

The Android verification workflow builds an ARM64 artifact signed with a disposable CI key. It is labeled `ci-verification` and cannot update a production release. The release workflow requires owner-configured signing secrets, an existing reviewed tag and matching release notes. Private keys and passwords are never committed.

## Privacy and attribution

No analytics are included. Android cloud backup is disabled; backups use destinations you select. Repositories and source sites receive requests when you use their services. Tracking credentials, when configured, belong in secure storage and are excluded from backups.

Dream Reader is not affiliated with Mihon or Keiyoushi. Vendored source API files retain upstream attribution and Apache-2.0 licensing. Fonts are distributed under the SIL Open Font License. See `assets/licenses/` and the in-app license page.


<!-- /coderabbit-ai-generated:v1 -->