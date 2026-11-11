<!-- coderabbit-ai-generated:v1 -->

<!-- coderabbit-ai-generated-section:v1:2fd76acce8685443b0404c11d8d1248f5953bd274078254bbc36dce45d2dabff -->

# Dream Reader architecture

Package `com.dreamreader.app`, Flutter presentation, Android ARM64 native engine, minimum Android 8.0 (API 26).

## Reference contracts

The adapter follows Mihon `134e5de3d672968b91ac426fbea0020290972cff`, Keiyoushi extensions-source `d0478bb62bbc485753d2830102aef4e1b87cb336`, and extensions-lib `42255ee5fa96d9425697b7c143587483207308d1`. Supported extension API versions are 1.4 and 1.6. Current sources use KeiSource and suspend APIs.

The deployed repository index is gzip-compressed protobuf. Its extension list is field 101; the deployed format and Mihon's NetworkExtensionStore govern parsing because the separate extensions-lib index.proto differs. Legacy JSON is accepted only when it contains actual extension entries. The catalogue is fetched, validated, cached and refreshed; production contains no bundled manga catalogue.

## Flutter and persistence

- Five destinations share a Material 3 design system, semantic controls, large-text layouts and dark/light/custom themes. Hidden destinations pause animation tickers.
- Drift stores library metadata, chapter progress, history and repository snapshots. Settings use SharedPreferences; tracker credentials use secure storage and are excluded from backups.
- Local startup does not wait for extension initialization. Source discovery runs in the background with loading and failure states; simultaneous refresh requests share the same work.
- Manga metadata is decoded once per library update. Indexed database queries page current-library updates instead of rendering every historical chapter.

## Native extension boundary

`ExtensionService` executes source code in `:extensions`. Source requests cross an Android Messenger bridge, then a Flutter method channel; source IDs remain strings. Responses above 128 KiB use validated private temporary files, with 32 MiB limits and cleanup, to avoid Binder transaction-size failures.

Installation requires explicit consent, HTTPS, cryptographic APK verification, the repository's signer fingerprint, matching package/version/API metadata and a compatible minimum SDK. Updates preserve signer identity and block downgrades. Constructors, every source ID and catalogue metadata are validated before replacing an installed APK. Candidate failures retain the previous package. Registration is atomic per extension; one bad source factory does not publish a partial package.

A lifecycle gate permits concurrent source reads and gives installation/removal exclusive access. Each source's ordinary requests remain sequential; different sources can progress independently. Image requests use separate locks. Long metadata and source-preference lookup stays off the UI thread.

The adapter exports pinned Mihon source interfaces and host dependencies. Injekt generic type metadata and dynamically linked APIs are preserved through R8. JavaScript uses Mihon's pinned QuickJS binding `547f5b1597e7f18984b1bdbee1ca5984b2175fa4`, with one interpreter per evaluation and native primitive results. HTTP image calls use the source's client and interceptors. Interactive website verification uses a cookie-sharing WebView.

**The extension process shares the app UID and is not a security sandbox.** Installed code can access application storage and the network. IPC deadlines bound the caller's wait; coroutine cancellation cannot forcibly interrupt arbitrary native JavaScript or uncooperative extension code. Process separation helps ordinary crash recovery but does not establish security isolation.

## Reader and downloads

Continuous and paged readers preserve chapter/page progress, bookmarks and preferences. A page is marked decoded only after an image frame is available; a failed final image does not complete a chapter. Complete downloads are read without contacting the source. Stale prefetch results cannot replace a newer chapter's state.

Tall Android images use BitmapRegionDecoder where supported. Regions are bounded to 1800×2048 decoded pixels, with two native decodes at a time. Flutter mounts visible regions and neighbours, then evicts their decoded image cache entries. Unsupported codecs use a bounded whole-image fallback. Actual codec support depends on Android; geometry and viewport tests do not establish device decoder behavior.

WorkManager owns chapter downloads. A configurable 1–6 slot limit and per-chapter locks coordinate workers, pause/resume and deletion. Finished pages are reused, metadata is replaced atomically, and damaged metadata is isolated as a deletable entry. Polling runs only while Downloads is active in the foreground. Images remain private application files.

## Backup and merge

Backups use a versioned JSON payload and SHA-256 integrity envelope with a 64 MiB encoded-size limit in both directions. Restore validates types, shows a preview, merges transactionally and preserves existing local records. Settings only fill missing values; appearance refreshes after import. SAF supplies user-selected import/export and scheduled-backup destinations. Download inventory is included; downloaded image files, extension APKs, credentials and source preferences are not.

Mihon protobuf imports cover titles, source IDs, metadata, chapters, read state, pages, bookmarks, categories and history. Multiple Mihon categories are represented by a combined category. Tracker sessions are not imported.

## Verification boundaries

Release checks inspect the actual APK's signature, manifest, architecture, 16 KB ZIP/ELF alignment, Injekt generic signatures and 1,030 class/member references from Atsumaru 1.6.26 and Kagane 1.6.42. These checks detect the observed release defects; they do not prove every extension's runtime behavior. Device acceptance remains with the owner, as requested. See [verification](verification.md).


<!-- /coderabbit-ai-generated:v1 -->