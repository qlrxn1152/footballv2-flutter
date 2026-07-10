import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/theme/app_theme.dart';
import 'package:footballv2_flutter/features/teams/data/team_models.dart';
import 'package:footballv2_flutter/features/teams/data/team_repository.dart';
import 'package:footballv2_flutter/features/teams/presentation/team_list_screen.dart';

void main() {
  testWidgets('팀 목록 헤더와 팀 카드를 유한한 너비로 렌더링한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teamsProvider.overrideWith(
            (ref) async => [
              TeamSummary.fromJson({
                'teamId': 3,
                'teamName': 'teamA',
                'teamRating': 1500,
                'leaderMemberId': 2,
                'leaderUsername': 'test',
                'memberCount': 1,
                'createdAt': '2026-07-09T00:00:00',
              }),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: TeamListScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('팀 레이팅 순 · 총 1개 팀'), findsOneWidget);
    expect(find.text('teamA'), findsOneWidget);
    expect(find.text('팀 만들기'), findsOneWidget);
  });
}
