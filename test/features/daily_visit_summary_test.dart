import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/features/analytics/data/daily_visit_summary.dart';

void main() {
  test('일별 사용 통계 응답을 변환한다', () {
    final summary = DailyVisitSummary.fromJson({
      'date': '2026-07-14',
      'uniqueVisitors': 8,
      'pageViews': 37,
    });

    expect(summary.date, DateTime(2026, 7, 14));
    expect(summary.uniqueVisitors, 8);
    expect(summary.pageViews, 37);
  });
}
