<!-- coderabbit-ai-generated:v1 -->

# Dream Reader architecture

Development session: 2026-11-11 16:39–18:39 UTC. Package `com.dreamreader.app`; Android ARM64.

## Evidence and compatibility

Research pins: Mihon `134e5de3d672968b91ac426fbea0020290972cff`, Keiyoushi extensions-source `d0478bb62bbc485753d2830102aef4e1b87cb336`, extensions-lib `42255ee5fa96d9425697b7c143587483207308d1`. Mihon supports API 1.4 and 1.6. Current Keiyoushi sources use KeiSource and suspend APIs. The current repository is gzip-compressed protobuf; its top-level embedded extension list is field 101. The extensions-lib index.proto differs from the currently deployed index, so the deployed wire format and Mihon's NetworkExtensionStore model govern parsing. Legacy JSON currently advertises upgrades and is not the catalogue.

## Components

- Flutter Material 3 presentation: original midnight/teal identity, five navigation destinations, adaptable themes, accessible reusable components and real empty/loading/error states.
- Drift SQLite persistence: library, chapters, history, categories, repositories and download metadata, indexed by source and manga. Settings remain local.
- Repository service: Dio, gzip/protobuf decoding, current index and optional legacy migration; user-controlled repository list and explicit default disclosure. Persist provenance and signer fingerprint.
- Kotlin extension compatibility module: pinned Mihon source interfaces and implementation, maintained dependency versions and documented adaptations. Extension packages are executable code; no sandbox claim. Consent, cryptographic APK verification and signer continuity are required before loading. A separate Android process provides crash separation but shares the app UID and is not a security sandbox.
- Typed platform channel boundary: repositories/installation, source listings, pagination, manga details, chapters, pages and preferences return serializable values. Long source IDs cross as strings. Native error codes become actionable UI states.
- Reader: lazy paged/continuous images, chapter progress, saved reading preferences and offline page lookup.
- Downloader: Android background work with persistent queue, bounded concurrency and resumable page-level completion.
- Backup: versioned JSON payload plus SHA-256 integrity envelope, SAF import/export, preview and transactional merge without silent replacement.

## Delivery gates

Analyze and test Dart, build release ARM64, verify manifest, ABI, archive and signatures. Install/launch/source/reader/download/restore journeys require an actual Android runtime. This sandbox has no /dev/kvm; software emulation or a remote device must be validated before runtime claims. Keep release signing material outside Git. Record verified coverage and remaining features explicitly in release notes.
