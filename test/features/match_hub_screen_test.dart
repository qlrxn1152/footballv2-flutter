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
    'homeScore': 3,
    'awayScore': 1,
    'winnerTeamId': 9,
    'winnerTeamName': 'teamE',
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

  testWidgets('전체, PENDING, MATCHED, COMPLETED 매치를 상태별로 표시한다', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen(homeLeader));
    await tester.pumpAndSettle();

    expect(find.text('전체'), findsOneWidget);
    expect(find.text('등록한 매치 대기 중'), findsOneWidget);
    expect(find.text('teamE 승리'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('match-hero-card'))).height,
      lessThan(190),
    );
    final schedulePanel = tester.getRect(
      find.byKey(const ValueKey('match-schedule-panel')),
    );
    for (final label in const ['전체', '대기', '매칭', '완료']) {
      expect(schedulePanel.contains(tester.getCenter(find.text(label))), isTrue);
    }

    await tester.tap(find.text('대기'));
    await tester.pumpAndSettle();
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
    expect(find.text('3 : 1'), findsOneWidget);
    expect(find.text('teamE 승리'), findsOneWidget);
    expect(find.text('COMPLETED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('다른 팀의 PENDING 매치에 매치 수락 버튼을 표시한다', (tester) async {
    await tester.pumpWidget(buildScreen(awayLeader));
    await tester.pumpAndSettle();

    await tester.tap(find.text('대기'));
    await tester.pumpAndSettle();
    expect(find.text('매치 수락'), findsOneWidget);
    await tester.tap(find.text('매치 수락'));
    await tester.pumpAndSettle();

    expect(find.text('매치 수락'), findsNWidgets(2));
    expect(find.textContaining('teamB 팀이 원정 팀으로 참가'), findsOneWidget);
    expect(find.text('수락하기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('매치 목록을 스크롤하면 상단 안내를 숨기고 필터만 작게 유지한다', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final manyPendingMatches = List.generate(
      8,
      (index) => TeamMatchSummary.fromJson({
        'teamMatchId': 100 + index,
        'homeTeamId': 20 + index,
        'homeTeamName': 'scroll-team-$index',
        'homeTeamRating': 1500 + index,
        'status': 'PENDING',
        'createdAt': '2026-07-14T12:00:00',
      }),
    );

    await tester.pumpWidget(
      buildScreen(
        homeLeader,
        pending: manyPendingMatches,
        matched: const [],
        completed: const [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('match-hero-card')), findsOneWidget);

    await tester.drag(find.byType(ListView).last, const Offset(0, -220));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('match-hero-card')), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('match-schedule-panel'))).height,
      lessThan(42),
    );
    for (final label in const ['전체', '대기', '매칭', '완료']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('경기일자를 가로로 표시하고 선택한 날짜의 매치만 보여준다', (
    tester,
  ) async {
    final firstDateMatch = TeamMatchSummary.fromJson({
      'teamMatchId': 31,
      'homeTeamId': 11,
      'homeTeamName': 'july20',
      'homeTeamRating': 1500,
      'status': 'PENDING',
      'playedAt': '2026-07-20T20:00:00',
      'createdAt': '2026-07-14T12:00:00',
    });
    final secondDateMatch = TeamMatchSummary.fromJson({
      'teamMatchId': 32,
      'homeTeamId': 12,
      'homeTeamName': 'july21',
      'homeTeamRating': 1510,
      'status': 'PENDING',
      'playedAt': '2026-07-21T21:00:00',
      'createdAt': '2026-07-14T13:00:00',
    });

    await tester.pumpWidget(
      buildScreen(
        homeLeader,
        pending: [firstDateMatch, secondDateMatch],
        matched: const [],
        completed: const [],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('대기'));
    await tester.pumpAndSettle();
    expect(find.text('경기 일정'), findsOneWidget);
    expect(find.text('07.20'), findsOneWidget);
    expect(find.text('07.21'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('match-date-20260720')));
    await tester.pumpAndSettle();
    expect(find.text('july20'), findsOneWidget);
    expect(find.text('july21'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('match-date-20260721')));
    await tester.pumpAndSettle();
    expect(find.text('july20'), findsNothing);
    expect(find.text('july21'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('match-date-all')));
    await tester.pumpAndSettle();
    expect(find.text('july20'), findsOneWidget);
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
    expect(find.text('teamA'), findsWidgets);
    expect(find.text('teamB'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('COMPLETED 무승부 매치의 스코어와 무승부를 표시한다', (tester) async {
    final drawMatch = TeamMatchSummary.fromJson({
      'teamMatchId': 25,
      'homeTeamId': 3,
      'homeTeamName': 'teamA',
      'homeTeamRating': 1500,
      'homeScore': 2,
      'awayTeamId': 4,
      'awayTeamName': 'teamB',
      'awayTeamRating': 1510,
      'awayScore': 2,
      'winnerTeamId': null,
      'winnerTeamName': null,
      'status': 'COMPLETED',
      'createdAt': '2026-07-11T18:00:00',
    });
    await tester.pumpWidget(
      buildScreen(
        homeLeader,
        pending: const [],
        matched: const [],
        completed: [drawMatch],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();
    expect(find.text('2 : 2'), findsOneWidget);
    expect(find.text('무승부'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
