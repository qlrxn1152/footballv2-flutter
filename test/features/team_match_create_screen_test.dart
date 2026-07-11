import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/theme/app_theme.dart';
import 'package:footballv2_flutter/features/matches/presentation/team_match_create_screen.dart';

void main() {
  testWidgets('매치 등록 전 홈 팀 정보와 등록 조건을 표시한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const TeamMatchCreateScreen(
            teamId: 3,
            teamName: 'teamA',
            teamRating: 1500,
          ),
        ),
      ),
    );

    expect(find.text('teamA'), findsOneWidget);
    expect(find.text('TEAM RATING 1500'), findsOneWidget);
    expect(find.textContaining('PENDING'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '매치 등록'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
