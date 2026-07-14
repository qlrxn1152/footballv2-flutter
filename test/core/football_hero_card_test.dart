import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/theme/app_theme.dart';
import 'package:footballv2_flutter/core/widgets/football_hero_card.dart';

void main() {
  testWidgets('축구장 스타일 공통 헤더를 작은 화면에서도 렌더링한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: FootballHeroCard(
              eyebrow: 'TEAM MATCH',
              title: '새로운 상대를 만나보세요',
              subtitle: '대기 중인 매치를 확인할 수 있습니다.',
              icon: Icons.sports_soccer,
              content: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: null,
                  child: Text('새 매치 등록'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('TEAM MATCH'), findsOneWidget);
    expect(find.text('새로운 상대를 만나보세요'), findsOneWidget);
    expect(find.text('새 매치 등록'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
