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

if [[ ! -d "web" ]]; then
  TEMP_WEB_ROOT="$(mktemp -d)"

  flutter create \
    --project-name footballv2_flutter \
    --org com.daehoon \
    --platforms web \
    --no-pub \
    "$TEMP_WEB_ROOT/footballv2_flutter"

  cp -R "$TEMP_WEB_ROOT/footballv2_flutter/web" "$PROJECT_ROOT/web"
  rm -rf "$TEMP_WEB_ROOT"
fi

"$PROJECT_ROOT/tool/configure_web.sh"

GRADLE_FILE="android/app/build.gradle.kts"
if [[ -f "$GRADLE_FILE" ]]; then
  sed -i.bak 's/minSdk = flutter.minSdkVersion/minSdk = 23/' "$GRADLE_FILE"
  rm -f "$GRADLE_FILE.bak"
fi

MAIN_MANIFEST_FILE="android/app/src/main/AndroidManifest.xml"
if [[ -f "$MAIN_MANIFEST_FILE" ]] && grep -q 'usesCleartextTraffic="true"' "$MAIN_MANIFEST_FILE"; then
  sed -i.bak 's/ android:usesCleartextTraffic="true"//' "$MAIN_MANIFEST_FILE"
  rm -f "$MAIN_MANIFEST_FILE.bak"
fi

DEBUG_MANIFEST_FILE="android/app/src/debug/AndroidManifest.xml"
mkdir -p "$(dirname "$DEBUG_MANIFEST_FILE")"
printf '%s\n' \
  '<manifest xmlns:android="http://schemas.android.com/apk/res/android">' \
  '    <uses-permission android:name="android.permission.INTERNET" />' \
  '    <application android:usesCleartextTraffic="true" />' \
  '</manifest>' \
  > "$DEBUG_MANIFEST_FILE"

flutter pub get
flutter analyze
flutter test

echo "준비 완료: flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080"
