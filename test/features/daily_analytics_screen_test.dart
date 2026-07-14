import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/features/analytics/data/daily_analytics_repository.dart';
import 'package:footballv2_flutter/features/analytics/data/daily_visit_summary.dart';
import 'package:footballv2_flutter/features/analytics/presentation/daily_analytics_screen.dart';

void main() {
  testWidgets('선택한 날짜의 순 사용자와 페이지 조회 수를 표시한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyVisitSummaryProvider('2026-07-14').overrideWith(
            (ref) async => DailyVisitSummary(
              date: DateTime(2026, 7, 14),
              uniqueVisitors: 8,
              pageViews: 37,
            ),
          ),
        ],
        child: MaterialApp(
          home: DailyAnalyticsScreen(initialDate: DateTime(2026, 7, 14)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026-07-14'), findsOneWidget);
    expect(find.text('순 사용자'), findsOneWidget);
    expect(find.text('8명'), findsOneWidget);
    expect(find.text('페이지 조회'), findsOneWidget);
    expect(find.text('37회'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
