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

sed -i.bak 's/<title>[^<]*<\/title>/<title>풋볼로그<\/title>/' "$INDEX_FILE"
sed -i.bak 's/content="footballv2_flutter"/content="풋볼로그"/' "$INDEX_FILE"
rm -f "$INDEX_FILE.bak"

sed -i.bak 's/"name": "footballv2_flutter"/"name": "풋볼로그"/' "$MANIFEST_FILE"
sed -i.bak 's/"short_name": "footballv2_flutter"/"short_name": "풋볼로그"/' "$MANIFEST_FILE"
sed -i.bak 's/"description": "A new Flutter project."/"description": "우리의 경기를 기록하는 풋볼로그"/' "$MANIFEST_FILE"
rm -f "$MANIFEST_FILE.bak"

rm -f "$PUSH_SCRIPT_FILE" "$PUSH_WORKER_FILE"

firebase_required=(
  FIREBASE_API_KEY
  FIREBASE_PROJECT_ID
  FIREBASE_MESSAGING_SENDER_ID
  FIREBASE_APP_ID
  FIREBASE_VAPID_KEY
)
firebase_configured=true
for variable in "${firebase_required[@]}"; do
  if [[ -z "${!variable:-}" ]]; then
    firebase_configured=false
    break
  fi
done

if [[ "$firebase_configured" == "true" ]]; then
  cp "$PUSH_SCRIPT_TEMPLATE" "$PUSH_SCRIPT_FILE"
  cp "$PUSH_WORKER_TEMPLATE" "$PUSH_WORKER_FILE"

  replace_placeholder() {
    local file="$1"
    local placeholder="$2"
    local value="$3"
    local escaped="${value//\\/\\\\}"
    escaped="${escaped//&/\\&}"
    escaped="${escaped//|/\\|}"
    sed -i.bak "s|$placeholder|$escaped|g" "$file"
    rm -f "$file.bak"
  }

  firebase_files=("$PUSH_SCRIPT_FILE" "$PUSH_WORKER_FILE")
  for file in "${firebase_files[@]}"; do
    replace_placeholder "$file" '__FIREBASE_API_KEY__' "$FIREBASE_API_KEY"
    replace_placeholder "$file" '__FIREBASE_AUTH_DOMAIN__' "${FIREBASE_AUTH_DOMAIN:-}"
    replace_placeholder "$file" '__FIREBASE_PROJECT_ID__' "$FIREBASE_PROJECT_ID"
    replace_placeholder "$file" '__FIREBASE_STORAGE_BUCKET__' "${FIREBASE_STORAGE_BUCKET:-}"
    replace_placeholder "$file" '__FIREBASE_MESSAGING_SENDER_ID__' "$FIREBASE_MESSAGING_SENDER_ID"
    replace_placeholder "$file" '__FIREBASE_APP_ID__' "$FIREBASE_APP_ID"
  done
  replace_placeholder "$PUSH_SCRIPT_FILE" '__FIREBASE_VAPID_KEY__' "$FIREBASE_VAPID_KEY"

  INDEX_TEMP="$INDEX_FILE.push.tmp"
  awk '
    /<script src="flutter_bootstrap.js" async><\/script>/ {
      print "  <script src=\"https://www.gstatic.com/firebasejs/12.16.0/firebase-app-compat.js\"></script>"
      print "  <script src=\"https://www.gstatic.com/firebasejs/12.16.0/firebase-messaging-compat.js\"></script>"
      print "  <script src=\"push-notifications.js\"></script>"
    }
    { print }
  ' "$INDEX_FILE" > "$INDEX_TEMP"
  mv "$INDEX_TEMP" "$INDEX_FILE"
else
  echo "Firebase 웹 설정값이 없어 푸시 알림 구성을 건너뜁니다."
fi
