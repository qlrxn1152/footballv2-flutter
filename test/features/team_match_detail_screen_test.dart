import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/theme/app_theme.dart';
import 'package:footballv2_flutter/features/matches/data/team_match.dart';
import 'package:footballv2_flutter/features/matches/data/team_match_repository.dart';
import 'package:footballv2_flutter/features/matches/presentation/team_match_detail_screen.dart';

void main() {
  testWidgets('완료된 매치의 일정과 결과를 표시한다', (tester) async {
    final detail = TeamMatchDetail.fromJson({
      'teamMatchId': 23,
      'homeTeamId': 3,
      'homeTeamName': 'teamA',
      'homeTeamRating': 1512,
      'awayTeamId': 4,
      'awayTeamName': 'teamB',
      'awayTeamRating': 1488,
      'status': 'COMPLETED',
      'createdAt': '2026-07-12T10:00:00',
      'playedAt': '2026-07-20T18:30:00',
      'homeScore': 3,
      'awayScore': 1,
      'winnerTeamId': 3,
      'winnerTeamName': 'teamA',
      'stadiumName': '월드컵 풋살장',
      'stadiumAddress': '서울시 마포구 월드컵로 1',
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teamMatchDetailProvider(23).overrideWith((ref) async => detail),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const TeamMatchDetailScreen(teamMatchId: 23),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('매치 상세'), findsOneWidget);
    expect(find.text('경기 완료'), findsOneWidget);
    expect(find.text('2026.07.20 18:30'), findsNWidgets(2));
    expect(find.text('3 : 1'), findsOneWidget);
    expect(find.text('teamA 승리'), findsOneWidget);
    expect(find.text('월드컵 풋살장'), findsOneWidget);
    expect(find.text('서울시 마포구 월드컵로 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
