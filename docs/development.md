<!-- coderabbit-ai-generated:v1 -->

<!-- coderabbit-ai-generated-section:v1:054cbb54104e20e06c29e041e252f6cef807d27fd1202e2fc3c6cdca17879812 -->

# Development and release operations

## Pinned environment

- Flutter stable 3.47.9, framework `c197ca5199e9ee5661e865596c9c07294dfab51c`, Dart 3.13.7.
- JDK 21, Android compile SDK 37.0, target SDK 36, minimum SDK 26.
- Android Gradle Plugin 9.5.1, Gradle 9.9.1, Kotlin 2.4.21.
- Flutter-selected NDK 28.2.13676358; build tools 36.0.0 with `zipalign -P 16`.

The SDK platform's sdkmanager package is `platforms;android-37.0`. Dependencies are pinned in Gradle declarations and `pubspec.lock`; do not update them as a side effect of a release build.

## Local verification

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test test
python3 -m unittest discover -s scripts/tests -v
(cd android && ./gradlew :app:testReleaseUnitTest :app:assembleReleaseAndroidTest -Ptarget-platform=android-arm64 -PdreamReleaseTest)
```

Run Flutter and Gradle commands serially. Flutter regenerates plugin registration between production and development operations. `dreamReleaseTest` enables integration dependencies only for test builds; never publish an app built with that flag. Android test APK compilation is separate from device execution.

The web preview exercises Flutter layouts, SQLite and repository parsing. Source execution, source preferences, native downloads and scheduled backups require Android.

```sh
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

The SQLite WASM runtime matches sqlite3 3.5.2. Regenerate the Drift worker when upgrading Drift:

```sh
dart compile js -O4 tool/drift_worker.dart -o web/drift_worker.dart.js
```

## Production signing and builds

Keep the keystore and properties file outside Git with owner-only permissions:

```properties
storeFile=/private/path/release.jks
storePassword=YOUR_PRIVATE_PASSWORD
keyAlias=dream-reader
keyPassword=YOUR_PRIVATE_PASSWORD
```

Set `DREAM_READER_SIGNING_PROPERTIES` to the file and `ANDROID_HOME` to the SDK. Back up the key using secure secret storage. Future updates require the same key and a higher Android version code. Do not upload signing material as release assets.

`scripts/build_release.sh` runs analysis, Flutter/Python tests, a production ARM64 build and static verification. It freezes that APK under `build/release/` before regenerating development bindings, running JVM tests and compiling Android acceptance tests. Outputs include `DreamReader-arm64-release.apk`, `SHA256SUMS`, `build-info.json` and `INSTALLATION.md`. Private obfuscation symbols remain under `build/private-symbols`.

## Release regression gates

`verify_apk.py` requires ARM64 Flutter and QuickJS libraries, verifies every ELF load segment and ZIP alignment for 16 KB compatibility, checks package identity and signature, rejects Flutter's integration-test channel, and records the actual checkout revision, dirty-tree status, version code and minimum API. Build final releases from clean commits.

`verify_extension_types.py` checks class-level DEX Signature annotations, including Injekt tokens generated in caller packages. Keeping only the Injekt package is insufficient with R8 full mode.

`dex_contract.py` compares actual DEX definitions against references from the pinned Atsumaru/Kagane APKs. Its fixture includes an absent class so references cannot count as definitions. To refresh a contract, download an official extension, record repository/version/SHA-256 provenance, inspect the extracted diff and retain the supported host APIs:

```sh
python3 scripts/dex_contract.py EXTENSION.apk
python3 scripts/dex_contract.py HOST.apk --contracts scripts/extension_contracts.json
```

QuickJS is pinned to Mihon's immutable reference revision. JitPack resolution is restricted to its dependency group. The final APK gate checks its ARM64 library's alignment. Static linkage cannot establish reflection or runtime behavior.

## Optional device acceptance

The owner has assigned device testing to themselves. CI's `run_device_tests` input defaults to false. Tests remain available without being reported as passes:

```sh
flutter test integration_test/source_journey_test.dart -d DEVICE_ID
```

The source journey fetches the live catalogue, checks consent and signer rejection, installs MangaDex, searches, retrieves chapters and images, downloads a chapter, merges a backup and visits navigation. `JavaScriptContractTest` covers the native adapter's primitive values and independent evaluation contexts. These require an actual Android runtime and, for source journeys, working external services.

To run release instrumentation with a prepared device, use the CI command documented in `.github/workflows/android.yml`. Verify installation of the separately frozen production APK afterward. Test artifacts must never be substituted for the production release.

## GitHub publication

Android verification uses a disposable CI key; its artifact cannot update production. The release workflow requires owner-configured `ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD` and `ANDROID_KEY_ALIAS` in the protected `release` environment. The development agent does not upload private keys automatically.

Update version/build number and `docs/releases/vX.Y.Z.md`, finish checks, commit, build, tag that commit, then publish the APK, checksum, build information and installation instructions. Release notes must distinguish performed checks from owner-managed device acceptance.


<!-- /coderabbit-ai-generated:v1 -->