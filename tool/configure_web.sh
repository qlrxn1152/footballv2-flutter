#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INDEX_FILE="$PROJECT_ROOT/web/index.html"
MANIFEST_FILE="$PROJECT_ROOT/web/manifest.json"

if [[ ! -f "$INDEX_FILE" || ! -f "$MANIFEST_FILE" ]]; then
  echo "web 플랫폼 파일이 없습니다. 먼저 flutter create --platforms web . 을 실행하세요."
  exit 1
fi

sed -i.bak 's/<title>[^<]*<\/title>/<title>FootballV2<\/title>/' "$INDEX_FILE"
sed -i.bak 's/content="footballv2_flutter"/content="FootballV2"/' "$INDEX_FILE"
rm -f "$INDEX_FILE.bak"

sed -i.bak 's/"name": "footballv2_flutter"/"name": "FootballV2"/' "$MANIFEST_FILE"
sed -i.bak 's/"short_name": "footballv2_flutter"/"short_name": "FootballV2"/' "$MANIFEST_FILE"
sed -i.bak 's/"description": "A new Flutter project."/"description": "조기축구 팀과 매치를 관리하는 FootballV2"/' "$MANIFEST_FILE"
rm -f "$MANIFEST_FILE.bak"
