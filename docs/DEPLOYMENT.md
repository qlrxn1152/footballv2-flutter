# FootballV2 Flutter Web 배포

## GitHub 설정

1. `footballv2-flutter` 저장소의 Settings로 이동한다.
2. Pages 메뉴에서 Source를 `GitHub Actions`로 선택한다.
3. Settings > Secrets and variables > Actions > Variables로 이동한다.
4. 다음 Repository variable을 만든다.

```text
Name: API_BASE_URL
Value: https://RAILWAY에서-생성한-백엔드-도메인
```

주소 마지막에 `/`는 붙이지 않는다.

5. Actions > `Deploy Flutter Web` > Run workflow를 실행한다.

배포 주소:

```text
https://qlrxn1152.github.io/footballv2-flutter/
```

## 홈 화면에 추가

- iPhone: Safari > 공유 > 홈 화면에 추가 > 웹 앱으로 열기
- Android: Chrome > 메뉴 > 앱 설치 또는 홈 화면에 추가

## 로컬 웹 확인

```bash
./tool/bootstrap.sh
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8080
```

GitHub Pages에서 API 호출이 성공하려면 백엔드의 `CORS_ALLOWED_ORIGINS`에
`https://qlrxn1152.github.io`가 등록되어 있어야 한다.

Android의 HTTP 허용 설정은 로컬 디버그 빌드에만 적용된다. 배포 빌드는 반드시
HTTPS인 Railway API 주소를 사용한다.
