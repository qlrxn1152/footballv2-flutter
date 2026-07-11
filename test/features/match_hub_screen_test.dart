import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/theme/app_theme.dart';
import 'package:footballv2_flutter/features/matches/data/team_match.dart';
import 'package:footballv2_flutter/features/matches/data/team_match_repository.dart';
import 'package:footballv2_flutter/features/matches/presentation/match_hub_screen.dart';
import 'package:footballv2_flutter/features/members/data/member_account.dart';
import 'package:footballv2_flutter/features/members/data/member_repository.dart';

void main() {
  testWidgets('PENDING 매치와 상태별 내부 탭을 표시한다', (tester) async {
    const member = MemberMe(
      memberId: 2,
      username: 'test',
      memberRating: 1500,
      teamId: 3,
      teamName: 'teamA',
      teamRole: 'LEADER',
      joinedAt: null,
      createdAt: null,
    );
    final match = PendingTeamMatch.fromJson({
      'teamMatchId': 21,
      'homeTeamId': 3,
      'homeTeamName': 'teamA',
      'homeTeamRating': 1500,
      'status': 'PENDING',
      'createdAt': '2026-07-11T14:30:00',
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memberMeProvider.overrideWith((ref) async => member),
          pendingTeamMatchesProvider.overrideWith(
            (ref) async => [match],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: MatchHubScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('등록한 매치 대기 중'), findsOneWidget);
    expect(find.text('teamA'), findsOneWidget);
    expect(find.text('매치 #21'), findsOneWidget);

    await tester.tap(find.text('매칭'));
    await tester.pump();
    expect(find.text('MATCHED 매치 조회 API 준비 중'), findsOneWidget);

    await tester.tap(find.text('완료'));
    await tester.pump();
    expect(find.text('COMPLETED 매치 조회 API 준비 중'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
