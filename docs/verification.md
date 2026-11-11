<!-- coderabbit-ai-generated:v1 -->

<!-- coderabbit-ai-generated-section:v1:2535fd344461650ecef5efcd5fa17a2611861fae701d0ff2310852ce4bcb6261 -->

# Verification status

This file records development status, not a claim of a completed production release. Update it with final artifact hashes and device evidence before publication.

## Verified so far

- Live official Keiyoushi catalogue parsing and signer-pin comparison; 1,587 entries in the observed catalogue.
- Browser preview initialization, database-backed navigation and catalogue refresh.
- Protobuf parser, backup checksum, transactional restore, metadata roundtrip and chapter-refresh regression tests.
- Current Mihon protobuf import tests, including packed categories, chapter float values and source metadata.
- Android x86_64 debug builds of the source runtime, source filter bridge, source-aware images and download worker.

## Outstanding release gates

- Latest native scheduled-backup additions compile; runtime checks remain outstanding.
- Android installation and source journey: the Android 15 software emulator failed during initial system startup. A lighter Android test image is being prepared; no successful device journey is claimed yet.
- Signed ARM64 release build, static verification, installation, launch and release-mode extension loading.
- Final source/release publication.
- Tracking OAuth sign-in requires registered public AniList/MyAnimeList client IDs and redirect URLs. Those credentials have been requested; no successful tracker sign-in is claimed.
- Broad extension compatibility, very large chapter decoding, large-library scrolling and background task behavior need measured device evidence.

## Import boundaries

Mihon imports cover saved titles, source IDs, metadata, chapters, read state, page positions, bookmarks, categories and reading history. Multiple categories are represented as a combined category. Tracker sessions, credentials, extension APKs and source preferences are not imported. Existing Dream Reader records are preserved. Download inventory can be backed up; downloaded image files are not part of a backup.


<!-- /coderabbit-ai-generated:v1 -->