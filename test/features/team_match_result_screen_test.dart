import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/theme/app_theme.dart';
import 'package:footballv2_flutter/features/matches/data/team_match.dart';
import 'package:footballv2_flutter/features/matches/presentation/team_match_result_screen.dart';
import 'package:footballv2_flutter/features/teams/data/team_models.dart';
import 'package:footballv2_flutter/features/teams/data/team_repository.dart';

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
  const homeMember = TeamMember(
    teamMemberId: 1,
    teamId: 3,
    teamName: 'teamA',
    memberId: 2,
    username: 'homePlayer',
    memberRating: 1500,
    teamRole: 'LEADER',
    joinedAt: null,
  );
  const awayMember = TeamMember(
    teamMemberId: 2,
    teamId: 4,
    teamName: 'teamB',
    memberId: 6,
    username: 'awayPlayer',
    memberRating: 1510,
    teamRole: 'LEADER',
    joinedAt: null,
  );

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        teamMembersProvider(
          3,
        ).overrideWith((ref) async => const [homeMember]),
        teamMembersProvider(
          4,
        ).overrideWith((ref) async => const [awayMember]),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: TeamMatchResultScreen(match: match),
      ),
    );
  }

  testWidgets('홈·원정 점수 입력 화면과 빈 값 검증을 표시한다', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsNWidgets(2));
    expect(find.text('AWAY'), findsNWidgets(2));
    expect(find.byType(TextFormField), findsNWidgets(2));

    await tester.tap(find.text('결과 등록'));
    await tester.pump();
    expect(find.text('점수를 입력해주세요.'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('점수와 득점자 합계를 맞춘 뒤 결과 등록을 확인한다', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    final scoreFields = find.byType(TextFormField);
    await tester.enterText(scoreFields.at(0), '1');
    await tester.enterText(scoreFields.at(1), '0');
    await tester.pump();

    await tester.tap(find.text('결과 등록'));
    await tester.pump();
    expect(find.textContaining('득점자 합계(0)가 다릅니다'), findsOneWidget);

    final homeGoalButton = find.byKey(const ValueKey('goal-plus-3-2'));
    await tester.ensureVisible(homeGoalButton);
    final addGoalButton = tester.widget<IconButton>(homeGoalButton);
    expect(addGoalButton.onPressed, isNotNull);
    addGoalButton.onPressed!();
    await tester.pump();
    expect(find.text('1 / 1골'), findsOneWidget);

    final submitButton = find.text('결과 등록');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(find.text('등록하기'), findsOneWidget);
    expect(find.textContaining('득점자 1명의 기록'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
