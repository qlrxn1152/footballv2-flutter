#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INDEX_FILE="$PROJECT_ROOT/web/index.html"
MANIFEST_FILE="$PROJECT_ROOT/web/manifest.json"
PUSH_SCRIPT_FILE="$PROJECT_ROOT/web/push-notifications.js"
PUSH_WORKER_FILE="$PROJECT_ROOT/web/firebase-messaging-sw.js"
PUSH_SCRIPT_TEMPLATE="$PROJECT_ROOT/tool/web/push-notifications.js.template"
PUSH_WORKER_TEMPLATE="$PROJECT_ROOT/tool/web/firebase-messaging-sw.js.template"

if [[ ! -f "$INDEX_FILE" || ! -f "$MANIFEST_FILE" ]]; then
  echo "web 플랫폼 파일이 없습니다. 먼저 flutter create --platforms web . 을 실행하세요."
  exit 1
fi

sed -i.bak 's/<title>[^<]*<\/title>/<title>Footmatch<\/title>/' "$INDEX_FILE"
sed -i.bak 's/content="footballv2_flutter"/content="Footmatch"/' "$INDEX_FILE"
rm -f "$INDEX_FILE.bak"

sed -i.bak 's/"name": "footballv2_flutter"/"name": "Footmatch"/' "$MANIFEST_FILE"
sed -i.bak 's/"short_name": "footballv2_flutter"/"short_name": "Footmatch"/' "$MANIFEST_FILE"
sed -i.bak 's/"description": "A new Flutter project."/"description": "우리의 경기를 기록하는 Footmatch"/' "$MANIFEST_FILE"
rm -f "$MANIFEST_FILE.bak"

rm -f "$PUSH_SCRIPT_FILE" "$PUSH_WORKER_FILE"

# Footmatch currently has no Firebase notification endpoints.
# Remove legacy script tags when reusing an existing web directory.
sed -i.bak '/firebasejs/d; /src="push-notifications.js"/d' "$INDEX_FILE"
rm -f "$INDEX_FILE.bak"
