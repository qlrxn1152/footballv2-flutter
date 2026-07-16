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

  testWidgets('상세 화면에서도 하단 탭을 유지하고 선택한 홈 탭으로 돌아간다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => FootballPageShell(
                      selectedIndex: 2,
                      child: Scaffold(
                        appBar: AppBar(title: const Text('팀 상세')),
                        body: const Center(child: Text('상세 내용')),
                      ),
                    ),
                  ),
                ),
                child: const Text('상세 열기'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('상세 열기'));
    await tester.pumpAndSettle();
    expect(find.text('팀 상세'), findsOneWidget);
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('선수'), findsOneWidget);
    expect(find.text('팀'), findsOneWidget);
    expect(find.text('매치'), findsOneWidget);
    expect(find.text('내 정보'), findsOneWidget);

    await tester.tap(find.text('매치'));
    await tester.pumpAndSettle();
    expect(find.text('상세 열기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
