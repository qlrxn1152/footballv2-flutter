#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INDEX_FILE="$PROJECT_ROOT/web/index.html"
MANIFEST_FILE="$PROJECT_ROOT/web/manifest.json"

if [[ ! -f "$INDEX_FILE" || ! -f "$MANIFEST_FILE" ]]; then
  echo "web 플랫폼 파일이 없습니다. 먼저 flutter create --platforms web . 을 실행하세요."
  exit 1
fi

sed -i.bak 's/<title>[^<]*<\/title>/<title>풋볼로그<\/title>/' "$INDEX_FILE"
sed -i.bak 's/content="footballv2_flutter"/content="풋볼로그"/' "$INDEX_FILE"
rm -f "$INDEX_FILE.bak"

sed -i.bak 's/"name": "footballv2_flutter"/"name": "풋볼로그"/' "$MANIFEST_FILE"
sed -i.bak 's/"short_name": "footballv2_flutter"/"short_name": "풋볼로그"/' "$MANIFEST_FILE"
sed -i.bak 's/"description": "A new Flutter project."/"description": "우리의 경기를 기록하는 풋볼로그"/' "$MANIFEST_FILE"
rm -f "$MANIFEST_FILE.bak"
