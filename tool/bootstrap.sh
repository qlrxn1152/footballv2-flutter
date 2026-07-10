#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK를 찾을 수 없습니다. https://docs.flutter.dev/get-started/install 에서 먼저 설치하세요."
  exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

if [[ ! -d "android" ]]; then
  TEMP_ROOT="$(mktemp -d)"
  trap 'rm -rf "$TEMP_ROOT"' EXIT

  flutter create \
    --project-name footballv2_flutter \
    --org com.daehoon \
    --platforms android \
    --no-pub \
    "$TEMP_ROOT/footballv2_flutter"

  cp -R "$TEMP_ROOT/footballv2_flutter/android" "$PROJECT_ROOT/android"
  cp "$TEMP_ROOT/footballv2_flutter/.metadata" "$PROJECT_ROOT/.metadata"
fi

GRADLE_FILE="android/app/build.gradle.kts"
if [[ -f "$GRADLE_FILE" ]]; then
  sed -i.bak 's/minSdk = flutter.minSdkVersion/minSdk = 23/' "$GRADLE_FILE"
  rm -f "$GRADLE_FILE.bak"
fi

MANIFEST_FILE="android/app/src/main/AndroidManifest.xml"
if [[ -f "$MANIFEST_FILE" ]] && ! grep -q 'usesCleartextTraffic' "$MANIFEST_FILE"; then
  sed -i.bak 's/<application/<application android:usesCleartextTraffic="true"/' "$MANIFEST_FILE"
  rm -f "$MANIFEST_FILE.bak"
fi

flutter pub get
flutter analyze
flutter test

echo "준비 완료: flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080"
