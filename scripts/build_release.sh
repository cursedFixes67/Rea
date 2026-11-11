#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter_command="${FLUTTER_BIN:-flutter}"
: "${DREAM_READER_SIGNING_PROPERTIES:?Set the path to private release signing properties}"
output_directory="${DREAM_READER_OUTPUT_DIR:-build/release}"
symbol_directory="${DREAM_READER_SYMBOLS_DIR:-build/private-symbols}"
sdk_directory="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
: "${sdk_directory:?Set ANDROID_HOME}"
build_tools="${ANDROID_BUILD_TOOLS_DIR:-$(find "$sdk_directory/build-tools" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -1)}"
"$flutter_command" pub get --enforce-lockfile
"$flutter_command" analyze
"$flutter_command" test test
"$flutter_command" build apk --release --target-platform android-arm64 --obfuscate --split-debug-info="$symbol_directory"
mkdir -p "$output_directory"
cp build/app/outputs/flutter-apk/app-release.apk "$output_directory/DreamReader-arm64-release.apk"
python3 scripts/verify_apk.py "$output_directory/DreamReader-arm64-release.apk" --build-tools "$build_tools"
