import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/theme/app_theme.dart';
import 'package:footballv2_flutter/features/matches/data/team_match_history.dart';
import 'package:footballv2_flutter/features/matches/data/team_match_repository.dart';
import 'package:footballv2_flutter/features/matches/presentation/team_match_history_section.dart';

void main() {
  final pending = TeamMatchHistory.fromJson({
    'teamMatchId': 31,
    'homeTeamId': 3,
    'homeTeamName': 'teamA',
    'awayTeamId': null,
    'awayTeamName': null,
    'status': 'PENDING',
    'createdAt': '2026-07-12T10:00:00',
    'playedAt': '2026-07-20T18:30:00',
    'homeScore': null,
    'awayScore': null,
    'winnerTeamId': null,
    'winnerTeamName': null,
  });
  final matched = TeamMatchHistory.fromJson({
    'teamMatchId': 32,
    'homeTeamId': 3,
    'homeTeamName': 'teamA',
    'awayTeamId': 4,
    'awayTeamName': 'teamB',
    'status': 'MATCHED',
    'createdAt': '2026-07-12T11:00:00',
    'playedAt': '2026-07-20T18:30:00',
    'homeScore': null,
    'awayScore': null,
    'winnerTeamId': null,
    'winnerTeamName': null,
  });
  final completed = TeamMatchHistory.fromJson({
    'teamMatchId': 33,
    'homeTeamId': 3,
    'homeTeamName': 'teamA',
    'awayTeamId': 4,
    'awayTeamName': 'teamB',
    'status': 'COMPLETED',
    'createdAt': '2026-07-12T12:00:00',
    'playedAt': '2026-07-20T18:30:00',
    'homeScore': 3,
    'awayScore': 1,
    'winnerTeamId': 3,
    'winnerTeamName': 'teamA',
  });

  testWidgets('팀의 상태별 매치 기록을 전환해 표시한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teamMatchHistoryProvider((
            teamId: 3,
            status: 'PENDING',
          )).overrideWith((ref) async => [pending]),
          teamMatchHistoryProvider((
            teamId: 3,
            status: 'MATCHED',
          )).overrideWith((ref) async => [matched]),
          teamMatchHistoryProvider((
            teamId: 3,
            status: 'COMPLETED',
          )).overrideWith((ref) async => [completed]),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: TeamMatchHistorySection(teamId: 3),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('매치 기록'), findsOneWidget);
    expect(find.text('상대 팀 대기 중'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);

    await tester.tap(find.text('매칭'));
    await tester.pumpAndSettle();
    expect(find.text('teamB'), findsOneWidget);
    expect(find.text('MATCHED'), findsOneWidget);

    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();
    expect(find.text('3 : 1'), findsOneWidget);
    expect(find.text('teamA 승리'), findsOneWidget);
    expect(find.text('COMPLETED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
