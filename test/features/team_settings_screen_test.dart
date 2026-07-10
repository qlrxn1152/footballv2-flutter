import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/theme/app_theme.dart';
import 'package:footballv2_flutter/features/teams/presentation/team_settings_screen.dart';

void main() {
  Widget app({required int memberCount}) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        home: TeamSettingsScreen(
          teamId: 3,
          teamName: 'teamA',
          memberCount: memberCount,
        ),
      ),
    );
  }

  testWidgets('팀원이 두 명 이상이면 팀 해체 버튼을 비활성화한다', (tester) async {
    await tester.pumpWidget(app(memberCount: 2));

    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, '팀원이 있어 해체할 수 없음'),
    );

    expect(button.onPressed, isNull);
    expect(find.textContaining('현재 2명이 소속'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('팀장만 남으면 팀 해체 버튼을 활성화한다', (tester) async {
    await tester.pumpWidget(app(memberCount: 1));

    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, '팀 해체'),
    );

    expect(button.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('현재 이름과 같은 팀 이름은 API 호출 전에 차단한다', (tester) async {
    await tester.pumpWidget(app(memberCount: 1));

    await tester.tap(find.widgetWithText(FilledButton, '팀 이름 변경'));
    await tester.pump();

    expect(find.text('현재 팀 이름과 다른 이름을 입력하세요.'), findsOneWidget);
  });
}
