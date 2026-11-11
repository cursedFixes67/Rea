<!-- coderabbit-ai-generated:v1 -->

<!-- coderabbit-ai-generated-section:v1:ba091cc29e33fb12990c2562e58bd1a78eb1af16d3e4b73c0957adbe6ea14393 -->

# Verification status

## Signed release candidate

Version 1.0.0, package `com.dreamreader.app`, minimum Android 8.0 (API 26), ARM64 only. Candidate built from `bb02a6730566af625a40067c1a909d90218135cb`. **Not published yet; device acceptance is outstanding.**

- APK: 25,056,340 bytes.
- SHA-256: `7b9aee70eca51953b11a8f26fc8f93bc9b223bff8cf431251508516c132844c8`.
- Signing certificate SHA-256: `881f2a3fa91f54dd556728334c9c598a31ddb2cdfe44e956a2618d255ebdfa4b`.
- Independently passed ZIP CRC, ARM64 ELF identification, package ID, release/not-debuggable checks, APK v2 signature and 16 KB ZIP/ELF alignment checks.
- Production DEX does not include Flutter's IntegrationTestPlugin.

## Completed development checks

- Flutter analysis: no issues.
- Thirteen unit/widget tests passed; a separate scale test also passed. These cover live-index fixtures, malformed protobuf, source metadata round trips, checksum verification, transactional backup merge, sticky read progress, Mihon imports and repository consent.
- SQLite scale fixture: 3,000 titles and 30,000 chapters; correct aggregates and indexed chapter retrieval. Host library and aggregate queries took 80 ms. This is not a phone rendering benchmark.
- Live official Keiyoushi catalogue fetched and parsed: 1,587 entries in the observed snapshot, signer pin checked.
- Flutter web release and Android debug/release compilation succeeded.
- Cloud browser navigation, catalogue refresh, Home customization persistence and appearance selection exercised.

## Outstanding device acceptance

The local sandbox has no hardware virtualization. Android 15 and Android 11 software emulators failed during system startup/package installation. Android 11 briefly reported completed boot, but its package manager subsequently became unavailable. No app test passed on those devices.

GitHub Actions now prepares an accelerated Android device and uses native instrumentation for the release-mode source journey. It must pass extension installation/signature rejection, loading, search, metadata, chapters, images, downloads, backup merge and navigation. ARM64 installation and launch follow that journey. Results are pending; compilation and static checks do not establish source compatibility.

Scheduled SAF backups, broad extension compatibility, very large image rendering, phone scrolling performance and background execution still require device evidence. Tracking sign-in requires registered public AniList/MyAnimeList client IDs; no tracker sign-in has been verified.

## Import boundaries

Mihon imports cover saved titles, source IDs, metadata, chapters, read state, page positions, bookmarks, categories and reading history. Multiple categories are represented as a combined category. Tracker sessions, credentials, extension APKs and source preferences are not imported. Existing Dream Reader records are preserved. Download inventory can be backed up; downloaded image files are not part of a backup.


<!-- /coderabbit-ai-generated:v1 -->