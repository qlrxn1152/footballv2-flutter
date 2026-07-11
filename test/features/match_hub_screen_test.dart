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
  const homeLeader = MemberMe(
    memberId: 2,
    username: 'test',
    memberRating: 1500,
    teamId: 3,
    teamName: 'teamA',
    teamRole: 'LEADER',
    joinedAt: null,
    createdAt: null,
  );
  const awayLeader = MemberMe(
    memberId: 6,
    username: 'away',
    memberRating: 1510,
    teamId: 4,
    teamName: 'teamB',
    teamRole: 'LEADER',
    joinedAt: null,
    createdAt: null,
  );
  final pendingMatch = TeamMatchSummary.fromJson({
    'teamMatchId': 21,
    'homeTeamId': 3,
    'homeTeamName': 'teamA',
    'homeTeamRating': 1500,
    'awayTeamId': null,
    'awayTeamName': null,
    'awayTeamRating': null,
    'status': 'PENDING',
    'createdAt': '2026-07-11T14:30:00',
  });
  final matchedMatch = TeamMatchSummary.fromJson({
    'teamMatchId': 22,
    'homeTeamId': 7,
    'homeTeamName': 'teamC',
    'homeTeamRating': 1490,
    'awayTeamId': 8,
    'awayTeamName': 'teamD',
    'awayTeamRating': 1520,
    'status': 'MATCHED',
    'createdAt': '2026-07-11T15:00:00',
  });
  final completedMatch = TeamMatchSummary.fromJson({
    'teamMatchId': 23,
    'homeTeamId': 9,
    'homeTeamName': 'teamE',
    'homeTeamRating': 1550,
    'awayTeamId': 10,
    'awayTeamName': 'teamF',
    'awayTeamRating': 1530,
    'status': 'COMPLETED',
    'createdAt': '2026-07-11T16:00:00',
  });

  Widget buildScreen(
    MemberMe member, {
    List<TeamMatchSummary>? pending,
    List<TeamMatchSummary>? matched,
    List<TeamMatchSummary>? completed,
  }) {
    return ProviderScope(
      overrides: [
        memberMeProvider.overrideWith((ref) async => member),
        teamMatchesProvider(
          'PENDING',
        ).overrideWith((ref) async => pending ?? [pendingMatch]),
        teamMatchesProvider(
          'MATCHED',
        ).overrideWith((ref) async => matched ?? [matchedMatch]),
        teamMatchesProvider(
          'COMPLETED',
        ).overrideWith((ref) async => completed ?? [completedMatch]),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: MatchHubScreen()),
      ),
    );
  }

  testWidgets('PENDING, MATCHED, COMPLETED 매치를 상태별로 표시한다', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen(homeLeader));
    await tester.pumpAndSettle();

    expect(find.text('등록한 매치 대기 중'), findsOneWidget);
    expect(find.text('teamA'), findsOneWidget);
    expect(find.text('내 팀 매치'), findsOneWidget);
    expect(find.text('매치 #21'), findsOneWidget);

    await tester.tap(find.text('매칭'));
    await tester.pumpAndSettle();
    expect(find.text('teamC'), findsOneWidget);
    expect(find.text('teamD'), findsOneWidget);
    expect(find.text('MATCHED'), findsOneWidget);

    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();
    expect(find.text('teamE'), findsOneWidget);
    expect(find.text('teamF'), findsOneWidget);
    expect(find.text('COMPLETED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('다른 팀의 PENDING 매치에 매치 수락 버튼을 표시한다', (tester) async {
    await tester.pumpWidget(buildScreen(awayLeader));
    await tester.pumpAndSettle();

    expect(find.text('매치 수락'), findsOneWidget);
    await tester.tap(find.text('매치 수락'));
    await tester.pumpAndSettle();

    expect(find.text('매치 수락'), findsNWidgets(2));
    expect(find.textContaining('teamB 팀이 원정 팀으로 참가'), findsOneWidget);
    expect(find.text('수락하기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('홈 팀장에게 MATCHED 매치 결과 입력 버튼을 표시한다', (tester) async {
    final ownMatchedMatch = TeamMatchSummary.fromJson({
      'teamMatchId': 24,
      'homeTeamId': 3,
      'homeTeamName': 'teamA',
      'homeTeamRating': 1500,
      'awayTeamId': 4,
      'awayTeamName': 'teamB',
      'awayTeamRating': 1510,
      'status': 'MATCHED',
      'createdAt': '2026-07-11T17:00:00',
    });
    await tester.pumpWidget(
      buildScreen(
        homeLeader,
        pending: const [],
        matched: [ownMatchedMatch],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('매칭'));
    await tester.pumpAndSettle();
    expect(find.text('결과 입력'), findsOneWidget);

    await tester.tap(find.text('결과 입력'));
    await tester.pumpAndSettle();
    expect(find.text('매치 결과 입력'), findsOneWidget);
    expect(find.text('teamA'), findsOneWidget);
    expect(find.text('teamB'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
