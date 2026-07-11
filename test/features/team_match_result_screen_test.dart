import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/theme/app_theme.dart';
import 'package:footballv2_flutter/features/matches/data/team_match.dart';
import 'package:footballv2_flutter/features/matches/presentation/team_match_result_screen.dart';

void main() {
  final match = TeamMatchSummary.fromJson({
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

  testWidgets('홈·원정 점수 입력 화면과 빈 값 검증을 표시한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: TeamMatchResultScreen(match: match),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('AWAY'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));

    await tester.tap(find.text('결과 등록'));
    await tester.pump();
    expect(find.text('점수를 입력해주세요.'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
