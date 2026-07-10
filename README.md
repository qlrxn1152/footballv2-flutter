# FootballV2 Flutter

FootballV2 Spring Boot REST API를 사용하는 Android Flutter 앱입니다.

## 구현 기능

- 회원가입 후 자동 로그인
- JWT와 회원 정보 보안 저장
- 선수 레이팅 랭킹
- 선수 상세 및 소속 팀 이동
- 팀 레이팅 목록
- 팀 상세 및 팀원 목록
- 팀 생성
- 팀 가입 신청
- 마이페이지와 현재 소속 팀 조회
- 내 팀 가입 신청 조회·취소
- 일반 팀원의 팀 탈퇴
- 팀 리더의 가입 신청 조회·수락·거절
- 로딩, 빈 목록, 네트워크 오류, 당겨서·탭·상단 버튼 새로고침 처리

## 사용 기술

- Flutter / Dart
- Material 3
- Riverpod
- Dio
- flutter_secure_storage

## 1. Flutter 설치

Mac에 Flutter가 없다면 [Flutter 공식 설치 문서](https://docs.flutter.dev/get-started/install/macos/mobile-android)를 따라 Flutter와 Android Studio를 설치합니다.

설치 확인:

```bash
flutter doctor
```

## 2. 프로젝트 최초 준비

프로젝트 루트에서 다음 명령을 실행합니다. Android 플랫폼 파일 생성, 최소 SDK 설정, 로컬 HTTP 허용, 패키지 설치, 분석과 테스트를 한 번에 수행합니다.

```bash
chmod +x tool/bootstrap.sh
./tool/bootstrap.sh
```

`flutter_secure_storage` 10.x의 요구사항에 맞춰 Android 최소 SDK는 23으로 설정됩니다.

## 3. 백엔드 실행

기존 `footballv2` Spring Boot 프로젝트를 `8080` 포트에서 실행합니다. Swagger에서 아래 API가 호출되는지 먼저 확인하면 문제를 찾기 쉽습니다.

```text
POST /api/auth/signup
POST /api/auth/login
GET  /api/members/ranking
GET  /api/members/me
GET  /api/members/me/team-join-requests
GET  /api/teams
```

## 4. Android 앱 실행

Android Studio에서 에뮬레이터를 실행한 뒤:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Android 에뮬레이터에서 `10.0.2.2`는 개발 PC의 `localhost`를 의미합니다.

실제 Android 기기를 사용할 때는 같은 Wi-Fi의 Mac IP를 지정합니다.

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8080
```

## 프로젝트 구조

```text
lib/
├── core/
│   ├── config/       # API 주소
│   ├── network/      # Dio, 공통 API 오류
│   ├── session/      # 로그인 세션 보안 저장
│   ├── theme/        # Material 3 테마
│   └── widgets/      # 공통 UI
└── features/
    ├── auth/         # 회원가입·로그인
    ├── home/         # 하단 내비게이션·내 정보
    ├── members/      # 선수 랭킹
    └── teams/        # 팀 목록·상세·가입 기능
```

UI는 `presentation`, 서버 호출과 JSON 변환은 `data`에 둡니다. 화면에서 Dio를 직접 호출하지 않도록 분리했습니다.

## 현재 백엔드 인증 방식

로그인 API는 JWT를 반환하지만, 팀 변경 API는 아직 `X-MEMBER-ID` 요청 헤더로 사용자를 식별합니다. 앱은 과도기 호환을 위해 두 헤더를 함께 전송합니다.

```text
Authorization: Bearer {accessToken}
X-MEMBER-ID: {memberId}
```

Spring의 JWT 인증 필터가 완성되면 `ApiClient`에서 `X-MEMBER-ID` 전송을 제거하면 됩니다.

## 검사 명령

```bash
flutter analyze
flutter test
```

## 아직 연결하지 않은 기능

- 매치: 백엔드 매치 API 구현 후 추가
- 토큰 갱신: 현재 백엔드에 refresh token API가 없음
