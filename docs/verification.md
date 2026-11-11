<!-- coderabbit-ai-generated:v1 -->

<!-- coderabbit-ai-generated-section:v1:de00d9b7e36096f53ba06954df51f492bfa1da77c5df04f929e735f2a930f69b -->

# Verification status

## Version 2 release checks

Version 2.0.0 uses package `com.dreamreader.app`, Android version code 2, minimum API 26 and ARM64 only. It retains version 1's production signing certificate:

```text
881f2a3fa91f54dd556728334c9c598a31ddb2cdfe44e956a2618d255ebdfa4b
```

Signed V2 candidates passed ZIP CRC, release/non-debuggable checks, package/ABI checks, Android signature verification and 16 KB ZIP/ELF alignment. The release asset `build-info.json` records the published binary's source commit, SHA-256 and size; `SHA256SUMS` independently identifies the APK. Reader region-channel names are checked in both compiled Dart and native DEX. These are binary-presence checks, not device execution.

The release DEX checks passed 60 Injekt generic type tokens and 1,030 actual host class/member references from Atsumaru 1.6.26 and Kagane 1.6.42. Negative checks rejected version 1's stripped type metadata, an earlier V2 checkpoint's missing Zstandard APIs, and an actual test-enabled APK containing Flutter's integration-test channel.

## Host and browser coverage

- Flutter analysis and all 52 Flutter tests passed, including source-search request ordering, offline reading, image failure/progress, viewport cancellation and populated large-text navigation.
- Six Python artifact-parser tests passed, including real DEX fixtures and inheritance/overload boundaries.
- Twenty-one Android JVM tests passed: payload-file boundaries, adjustable download concurrency, image-region geometry, queued decode cancellation, extension lifecycle locking and atomic source registration.
- Android acceptance test sources and APK compiled successfully after aligning Flutter's older transitive test dependencies. No instrumentation execution is claimed.
- The pinned QuickJS JNI sources passed a Linux host harness for primitive values, errors, 24 concurrent independent evaluations and context reset. This is not an Android binary execution.
- SQLite scale fixture: 3,000 titles and 30,000 chapters, correct indexed/paginated results. Observed host queries were approximately 14 ms for the first 201 update rows and 100 ms for library/aggregate retrieval; these are not phone frame-rate measurements.
- The live official catalogue was parsed with 1,587 observed entries. Cloud Preview exercised catalogue refresh, Atsumaru/Kagane visibility with adult-only sources disabled, Home customization, Theme Studio and dark/light appearances.

## Device acceptance remains with the owner

The owner explicitly requested publication and assigned device testing to themselves. That changes the publication gate; it does not convert unperformed checks into passes. No installation, launch or extension-execution success is claimed on an Android device. CI device journeys are optional and off by default.

Phone checks include installation over version 1, Atsumaru/Kagane installation and loading, source search/chapters/images, long-image decoding, reader controls, background downloads, SAF backup scheduling and restore. OEM background restrictions, source-site changes and Android codec support require runtime evidence. Static linkage covers the observed extension versions, not the whole ecosystem.

Tracker sign-in requires registered public AniList/MyAnimeList client IDs and has not been verified with live accounts. No unnecessary telemetry is included.

## Import boundaries

Mihon imports cover saved titles, source IDs, metadata, chapters, read state, page positions, bookmarks, categories and history. Multiple categories become a combined category. Tracker sessions, credentials, extension APKs and source preferences are excluded. Existing Dream Reader records are preserved. Backup download inventory contains metadata, not downloaded image files.

<!-- /coderabbit-ai-generated:v1 -->