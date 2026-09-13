# Footmatch 웹 연결

현재 배포 백엔드: https://footmatches.up.railway.app
프런트는 기존 footballv2-flutter 저장소와 GitHub Pages를 사용합니다.
서비스 표시는 Footmatch로 변경했습니다.

## 연결된 기능

- 회원가입 POST /api/members, 로그인, 자동 로그인, 내 정보
- 팀 번호 조회, 팀원 조회, 팀 생성, 이름 변경
- 가입 신청, 신청 번호를 통한 수락/거절/취소, 대기 신청 조회
- 팀 탈퇴, 회원 번호를 통한 팀장 위임/팀원 내보내기
- 경기 등록, 경기 번호를 통한 참가 신청
- 작업 결과 번호 복사, 요청 중 중복 클릭 방지, 오류 표시

기존 백엔드와 다른 응답 필드/경로를 새 repository에서 처리합니다.
Footmatch 로그인 응답에는 memberRating이 없으므로 선택 필드로 처리하고,
새 내 정보 화면의 레이팅은 GET /api/members/me에서 읽습니다.
세션 키는 백엔드 주소별로 분리되어 예전 토큰을 새 서버에 보내지 않습니다.
가입/로그인에는 Authorization 헤더를 보내지 않습니다.

## 현재 백엔드의 조회 제한

배포 브랜치에는 전체 팀 목록, 내 소속 팀, 선수 목록/랭킹, 경기 목록/상세/결과,
공지/게시판/알림/방문 통계 API가 없습니다. 기존 화면 코드는 보관하지만 앱의
현재 진입 화면에서 이 API들을 호출하지 않습니다. 득점자 입력/배포는 추가하지 않았습니다.

팀원 목록에는 memberId가 없고 가입 신청 목록에는 requestId가 없으므로
관리 작업에는 회원/신청 번호를 직접 입력합니다. 신청자는 가입 신청 직후
표시된 번호를 팀장에게 전달할 수 있습니다. 팀 번호/신청 번호/경기 번호는
'내 정보 → 이번 접속의 처리 내역'에서 복사할 수 있습니다.
이 목록은 이번 접속 중의 작업 결과이며 서버의 전체 이력이 아닙니다.
새로고침·로그아웃 전에 필요한 번호를 복사하세요.

이 조회 API와 식별자가 추가되면 ID 입력을 목록 선택 화면으로 교체할 수 있습니다.
프런트에서 전체 DB나 임의의 번호를 순회해 조회하지 않습니다.

## 적용 후 검사

Flutter 프로젝트 루트에서 실행합니다.

```bash
flutter pub get
flutter analyze
flutter test
```

웹 플랫폼 폴더가 없으면 다음을 실행합니다.

```bash
flutter create --platforms web .
```

웹 표시 설정 후 빌드합니다.

```bash
bash tool/configure_web.sh
flutter build web --release --base-href /footballv2-flutter/ --dart-define=API_BASE_URL=https://footmatches.up.railway.app
```

프런트 CI도 analyze/test를 통과해야 배포합니다.
기존 API_BASE_URL 저장소 변수로 예전 서버를 다시 가리키지 않도록
배포 workflow에서 Footmatch 주소를 명시합니다.

## GitHub Pages 배포

검사 성공 후 변경 브랜치를 main에 병합하고 main을 push하면 기존 Deploy Flutter Web
workflow가 배포합니다. GitHub Settings → Pages의 Source는 GitHub Actions여야 합니다.
기존 주소 https://qlrxn1152.github.io/footballv2-flutter/ 로 확인합니다.
저장소 이름까지 변경한다면 workflow의 --base-href도 해당 경로로 수정해야 합니다.

새 버전은 Footmatch 회원 계정으로 로그인합니다. 예전 FootballV2 회원은 새 빈 DB에 없습니다.
처음에는 신규 가입부터 진행합니다.

## 실제 확인 순서

1. 새 계정 가입 → 자동 로그인 → 내 정보의 회원 번호/레이팅 확인
2. 팀 생성 → 팀 번호와 상세/팀원 표시 확인 → 번호 복사
3. 로그아웃 후 두 번째 계정 가입 → 팀 번호로 조회 → 가입 신청 → 신청 번호 복사
4. 첫 계정 로그인 → 팀 조회 → 신청 목록 확인 → 신청 번호로 수락
5. 두 번째 계정으로 팀 조회/탈퇴, 첫 계정으로 이름 변경 등을 확인
6. 팀장 계정으로 경기 등록 → 경기 번호 보관 → 다른 팀장 계정으로 참가 신청

브라우저 계정 전환은 로그아웃 후 진행합니다. 서버가 반환한 401은 로그인 화면으로 돌아갑니다.
경기 날짜/시간은 현재 백엔드의 LocalDateTime 계약대로 시간대 오프셋 없이 전송합니다.
한국 운영 환경에서는 브라우저와 백엔드의 기준 시간대를 함께 확인하세요.

## 이 작업 환경의 검증 한계

Flutter/Dart SDK가 설치되어 있지 않고 SDK 다운로드 호스트 접속도 실패하여
여기서는 Flutter analyze/test/build 및 실제 브라우저 렌더링을 실행하지 못했습니다.
소스 경로/DTO 대조, 셸 문법, Git diff 검사는 수행했습니다.
추가된 계약 테스트는 새 인증 응답, JWT 전달, 가입 신청 URL, 경기 요청, 빈 응답 처리를 검증하고,
위젯 테스트는 홈에서 구버전 목록 API를 호출하지 않는지 확인합니다.
실제 배포 완료나 실서비스 변경 API 검증을 주장하지 않습니다.

참고: https://docs.flutter.dev/deployment/web
