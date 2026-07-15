import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/features/home/presentation/home_navigation.dart';

void main() {
  testWidgets('공용 하단 네비게이션에서 선택한 홈 탭으로 변경한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              final index = ref.watch(homeTabIndexProvider);
              return Scaffold(
                body: Text('선택 탭 $index'),
                bottomNavigationBar: FootballNavigationBar(
                  selectedIndex: index,
                  onDestinationSelected: ref
                      .read(homeTabIndexProvider.notifier)
                      .select,
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('선택 탭 0'), findsOneWidget);
    await tester.tap(find.text('선수'));
    await tester.pumpAndSettle();
    expect(find.text('선택 탭 1'), findsOneWidget);

    await tester.tap(find.text('팀'));
    await tester.pumpAndSettle();
    expect(find.text('선택 탭 2'), findsOneWidget);

    await tester.tap(find.text('매치'));
    await tester.pumpAndSettle();
    expect(find.text('선택 탭 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
