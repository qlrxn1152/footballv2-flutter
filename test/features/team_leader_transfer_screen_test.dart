import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/theme/app_theme.dart';
import 'package:footballv2_flutter/features/teams/data/team_models.dart';
import 'package:footballv2_flutter/features/teams/data/team_repository.dart';
import 'package:footballv2_flutter/features/teams/presentation/team_leader_transfer_screen.dart';

void main() {
  testWidgets('현재 팀장을 제외한 팀원만 위임 후보로 표시한다', (tester) async {
    const leader = TeamMember(
      teamMemberId: 1,
      teamId: 3,
      teamName: 'teamA',
      memberId: 2,
      username: 'currentLeader',
      memberRating: 1500,
      teamRole: 'LEADER',
      joinedAt: null,
    );
    const member = TeamMember(
      teamMemberId: 2,
      teamId: 3,
      teamName: 'teamA',
      memberId: 7,
      username: 'newLeader',
      memberRating: 1510,
      teamRole: 'MEMBER',
      joinedAt: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teamMembersProvider(3).overrideWith(
            (ref) async => const [leader, member],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const TeamLeaderTransferScreen(
            teamId: 3,
            teamName: 'teamA',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('currentLeader'), findsNothing);
    expect(find.text('newLeader'), findsOneWidget);

    await tester.tap(find.text('newLeader'));
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '선택한 팀원에게 위임'),
    );
    expect(button.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
