# Firebase 웹 푸시 운영 설정

Flutter 운영 배포에서 Firebase Cloud Messaging을 활성화하려면 저장소의
`Settings → Secrets and variables → Actions → Variables`에 다음 값을 등록합니다.

- `FIREBASE_API_KEY`
- `FIREBASE_AUTH_DOMAIN`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_APP_ID`
- `FIREBASE_VAPID_KEY`

앞의 여섯 값은 Firebase Console의 **프로젝트 설정 → 내 앱 → 웹 앱 → SDK 설정 및 구성**에서
확인합니다. `FIREBASE_VAPID_KEY`는 **프로젝트 설정 → Cloud Messaging → 웹 구성 → 웹 푸시 인증서**의
공개 키를 사용합니다.

변수 등록 후 GitHub의 **Actions → Deploy Flutter Web → Run workflow**를 한 번 실행하면
서비스 워커와 Firebase 설정이 포함된 웹앱이 다시 배포됩니다.

백엔드 Railway 서비스에는 별도로 다음 값이 필요합니다.

- `FIREBASE_ENABLED=true`
- `FIREBASE_SERVICE_ACCOUNT_BASE64`: Firebase 서비스 계정 JSON 파일 전체를 Base64로 인코딩한 값

서비스 계정 JSON이나 비공개 키는 저장소와 Flutter 코드에 커밋하지 않습니다.
