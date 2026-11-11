<!-- coderabbit-ai-generated:v1 -->

# Development and release operations

## Pinned environment

- Flutter stable 3.47.9, framework `c197ca5199e9ee5661e865596c9c07294dfab51c`, Dart 3.13.7.
- JDK 21. Android compile SDK 37.0; target SDK follows the pinned Flutter toolchain. Minimum SDK 26.
- Android Gradle Plugin 9.5.1, Gradle 9.9.1, Kotlin 2.4.21.
- Flutter-selected NDK. Build tools 36 or newer with `zipalign -P 16` support.

The SDK platform was installed with the Android CLI using `platforms/android-37.0@2.0.0`. The conventional sdkmanager package is `platforms;android-37.0`.

## Local commands

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test test
flutter run
```

The browser preview exercises Flutter layouts, the database and repository parsing. Native source execution, downloads, source preferences and scheduled backups require Android.

```sh
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

The SQLite WASM runtime is the matching sqlite3 3.5.2 release asset. The Drift worker is built from `tool/drift_worker.dart`. Regenerate it when upgrading Drift:

```sh
dart compile js -O4 tool/drift_worker.dart -o web/drift_worker.dart.js
```

## Release signing

Keep the keystore and this properties file outside Git, with owner-only filesystem permissions:

```properties
storeFile=/private/path/release.jks
storePassword=YOUR_PRIVATE_PASSWORD
keyAlias=dream-reader
keyPassword=YOUR_PRIVATE_PASSWORD
```

Set `DREAM_READER_SIGNING_PROPERTIES` to that file. Back up the key using your own secure secret-storage procedure. Future releases must use the same key and a higher Android version code to update installed copies. Losing the key prevents normal updates.

`scripts/build_release.sh` refuses missing signing configuration. It does not silently use a debug key. Obfuscation symbols remain under `build/private-symbols`; keep them privately for crash symbolication. Do not upload the signing file, keystore or passwords as release assets.

## Device journey

The integration test fetches the live catalogue, checks explicit installation consent and signer rejection, installs MangaDex from the current catalogue, searches, retrieves chapters, decodes an image, downloads a chapter, merges a backup and visits primary navigation. It requires network access and a working Android device; external source changes may legitimately fail the test.

```sh
flutter test integration_test/source_journey_test.dart -d DEVICE_ID
```

For constrained hosts, build first, stop Gradle daemons, then run the prebuilt test binary:

```sh
flutter build apk --debug --target-platform android-x64 -t integration_test/source_journey_test.dart
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/source_journey_test.dart --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk -d DEVICE_ID
```

The integration binary is a debug test artifact and must never be published as the release APK. Release installation and launch must be checked separately, including source loading after R8 optimization.

## Release automation

`.github/workflows/android.yml` uses a temporary verification key. `.github/workflows/release.yml` expects `ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD` and `ANDROID_KEY_ALIAS` to be configured by the repository owner in the protected `release` environment. No production key is uploaded automatically by the development agent.

Create reviewed release notes at `docs/releases/vX.Y.Z.md`, update the version/build number, run verification, commit and tag, then publish `DreamReader-arm64-release.apk`, `SHA256SUMS`, `build-info.json`, changelog and installation instructions. Release notes must distinguish checks that actually ran from blocked or unverified checks.
