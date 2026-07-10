import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/session/auth_session.dart';

void main() {
  test('로그인 응답을 세션으로 변환한다', () {
    final before = DateTime.now();

    final session = AuthSession.fromLoginJson({
      'accessToken': 'token-value',
      'tokenType': 'Bearer',
      'expiresIn': 3600,
      'memberId': 7,
      'username': 'player7',
      'memberRating': 1550,
    });

    expect(session.accessToken, 'token-value');
    expect(session.memberId, 7);
    expect(session.username, 'player7');
    expect(session.memberRating, 1550);
    expect(session.expiresAt.isAfter(before), isTrue);
    expect(session.isExpired, isFalse);
  });
}
