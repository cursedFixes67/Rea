<!-- coderabbit-ai-generated:v1 -->

<!-- coderabbit-ai-generated-section:v1:0411c32443d8f56de211b218f5dd69bdfc2d6bf5ed9c01fbafdd4c803b96fcd4 -->

# Verification status

## Version 2 development checkpoints

Version 2.0.0 uses package `com.dreamreader.app`, Android version code 2, minimum API 26 and ARM64 only. It retains version 1's production signing certificate:

```text
881f2a3fa91f54dd556728334c9c598a31ddb2cdfe44e956a2618d255ebdfa4b
```

The signed checkpoint containing the native QuickJS adapter passed ZIP CRC, release/non-debuggable checks, package/ABI checks, Android signature verification and 16 KB ZIP/ELF alignment. Its APK SHA-256 was `36d892cb19f1494295336bfedb383576d3392e3441bddb96b896df895572f735`. This is a development checkpoint; final release assets identify the published binary.

The release DEX checks passed 60 Injekt generic type tokens and 1,030 actual host class/member references from Atsumaru 1.6.26 and Kagane 1.6.42. Negative checks rejected version 1's stripped type metadata, an earlier V2 checkpoint's missing Zstandard APIs, and an actual test-enabled APK containing Flutter's integration-test channel.

## Host and browser coverage

- Flutter analysis passed. The 48-case full suite passed before the latest search/cover-transition refinements; fresh coverage is recorded with the final release.
- Six Python artifact-parser tests passed, including real DEX fixtures and inheritance/overload boundaries.
- Eighteen Android JVM tests passed: payload-file boundaries, adjustable download concurrency, image-region geometry, extension lifecycle locking and atomic source registration.
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