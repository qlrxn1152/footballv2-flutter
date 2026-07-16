import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/theme/app_theme.dart';
import 'package:footballv2_flutter/features/home/presentation/profile_screen.dart';
import 'package:footballv2_flutter/features/members/data/member_account.dart';
import 'package:footballv2_flutter/features/members/data/member_repository.dart';

void main() {
  const memberWithTeam = MemberMe(
    memberId: 2,
    username: 'test',
    memberRating: 1530,
    authority: 'ADMIN',
    teamId: 3,
    teamName: 'teamA',
    teamRole: 'LEADER',
    joinedAt: null,
    createdAt: null,
  );

  testWidgets('가입한 팀을 내 정보 카드에 표시하고 가입 신청 영역을 숨긴다', (
    tester,
  ) async {
    var joinRequestLoads = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memberMeProvider.overrideWith((ref) async => memberWithTeam),
          myTeamJoinRequestsProvider.overrideWith((ref) async {
            joinRequestLoads++;
            return const [];
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ProfileScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('test'), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-badge')), findsOneWidget);
    expect(find.text('1530'), findsOneWidget);
    expect(find.text('MY TEAM'), findsOneWidget);
    expect(find.text('teamA'), findsOneWidget);
    expect(find.text('내 가입 신청'), findsNothing);
    expect(joinRequestLoads, 0);

    final teamLink = tester.widget<InkWell>(
      find.byKey(const ValueKey('profile-team-link')),
    );
    expect(teamLink.onTap, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('소속 팀이 없을 때만 가입 신청 영역을 표시한다', (tester) async {
    const memberWithoutTeam = MemberMe(
      memberId: 7,
      username: 'new-member',
      memberRating: 1500,
      teamId: null,
      teamName: null,
      teamRole: null,
      joinedAt: null,
      createdAt: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memberMeProvider.overrideWith((ref) async => memberWithoutTeam),
          myTeamJoinRequestsProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ProfileScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('소속 팀 없음'), findsOneWidget);
    expect(find.text('내 가입 신청'), findsOneWidget);
    expect(find.text('대기 중인 팀 가입 신청이 없습니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
