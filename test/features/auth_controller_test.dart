import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/session/auth_session.dart';
import 'package:footballv2_flutter/features/auth/data/auth_repository.dart';
import 'package:footballv2_flutter/features/auth/presentation/auth_controller.dart';
import 'package:footballv2_flutter/features/members/data/member_ranking.dart';
import 'package:footballv2_flutter/features/members/data/member_repository.dart';

void main() {
  test('회원가입 후 기존 선수 랭킹 캐시를 갱신한다', () async {
    final repository = _FakeAuthRepository();
    var rankingLoads = 0;
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        memberRankingsProvider.overrideWith((ref) async {
          rankingLoads++;
          return [
            const MemberRanking(
              rank: 1,
              memberId: 1,
              username: '기존선수',
              rating: 1500,
            ),
            if (repository.signedUp)
              const MemberRanking(
                rank: 2,
                memberId: 2,
                username: '새선수',
                rating: 1500,
              ),
          ];
        }),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(authControllerProvider).status,
      AuthStatus.initializing,
    );
    await Future<void>.delayed(Duration.zero);
    final subscription = container.listen(memberRankingsProvider, (_, _) {});
    addTearDown(subscription.close);

    final beforeSignup = await container.read(memberRankingsProvider.future);
    expect(beforeSignup.map((member) => member.username), ['기존선수']);

    final success = await container
        .read(authControllerProvider.notifier)
        .signupAndLogin(username: '새선수', password: '1234');
    final afterSignup = await container.read(memberRankingsProvider.future);

    expect(success, isTrue);
    expect(afterSignup.map((member) => member.username), ['기존선수', '새선수']);
    expect(rankingLoads, 2);
  });
}

class _FakeAuthRepository implements AuthRepository {
  bool signedUp = false;

  @override
  Future<void> signup({
    required String username,
    required String password,
  }) async {
    signedUp = true;
  }

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    return AuthSession(
      accessToken: 'token',
      tokenType: 'Bearer',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      memberId: 2,
      username: username,
      memberRating: 1500,
    );
  }

  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<void> logout() async {}
}
