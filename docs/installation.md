<!-- coderabbit-ai-generated:v1 -->

# Installing Dream Reader

## Device requirements

- Android 8.0 or newer (API 26+).
- An ARM64 device with a 64-bit Android userspace (`arm64-v8a`). A 64-bit processor running a 32-bit Android system is not sufficient.
- Free space for the application, its database and any downloaded chapters.

## Install a published release

Download `DreamReader-arm64-release.apk` and `SHA256SUMS` from the matching [Dream Reader GitHub release](https://github.com/cursedFixes67/Rea/releases). Release candidates discussed in development notes are not published releases.

Open the APK on your phone and allow installation from the browser or file manager when Android asks. Follow the system installer. On first launch, review the Keiyoushi repository disclosure; you can disable it and manage repositories later in Settings. Each extension installation requires its own trust decision.

Dream Reader uses package ID `com.dreamreader.app`. It installs independently of StarReader and Mihon. Dream Reader supports an import preview for compatible Mihon backups; it does not automatically read another application's private data.

## Verify the file

On Linux or macOS, place the APK beside `SHA256SUMS` and run `sha256sum -c SHA256SUMS` (macOS can use `shasum -a 256 -c SHA256SUMS`). The checksum must match the same release, not an earlier version.

The Dream Reader production signing certificate SHA-256 is:

`881f2a3fa91f54dd556728334c9c598a31ddb2cdfe44e956a2618d255ebdfa4b`

Android SDK users can inspect it with `apksigner verify --verbose --print-certs DreamReader-arm64-release.apk`.

## Updating

Install the newer APK over the existing application. Production versions use the same signing key and increasing version codes. Export a backup from Settings before an update. CI verification APKs have disposable signing keys and cannot update a production installation.

## Installation problems

Use the exact Android error to diagnose a failure. A generic “App not installed” message does not identify the cause. With Android platform tools and USB debugging enabled, `adb install -r DreamReader-arm64-release.apk` reports the installer error.

- `INSTALL_FAILED_NO_MATCHING_ABIS`: check that `adb shell getprop ro.product.cpu.abilist` includes `arm64-v8a`.
- `INSTALL_FAILED_OLDER_SDK`: the phone must meet API 26 or newer.
- `INSTALL_FAILED_UPDATE_INCOMPATIBLE`: the existing package uses a different signing certificate, often a CI/debug build. Export its data before deciding whether to remove it; uninstalling deletes private app data.
- `INSTALL_FAILED_VERSION_DOWNGRADE`: install a newer production version. Do not force a downgrade over a newer database.
- `INSTALL_FAILED_INSUFFICIENT_STORAGE`: make space on the phone and retry.
- Package parsing or invalid APK errors: download the file again and verify its checksum.

If a verified release still fails, include the phone model, Android version, ABI list and exact installer error in the issue. Do not share signing credentials or account tokens.
