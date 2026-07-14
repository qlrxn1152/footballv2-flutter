import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/analytics/app_visit_tracker.dart';
import 'package:footballv2_flutter/core/analytics/visit_analytics_repository.dart';

void main() {
  testWidgets('최상단 위젯이 앱 시작 방문을 한 번 기록한다', (tester) async {
    final repository = _FakeVisitAnalyticsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          visitAnalyticsRepositoryProvider.overrideWithValue(repository),
        ],
        child: const AppVisitTracker(
          child: MaterialApp(home: Text('FootballV2')),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('FootballV2'), findsOneWidget);
    expect(repository.callCount, 1);
    expect(repository.lastPath, '/');
  });
}

class _FakeVisitAnalyticsRepository implements VisitAnalyticsRepository {
  int callCount = 0;
  String? lastPath;

  @override
  Future<void> recordAppOpen({String path = '/'}) async {
    callCount++;
    lastPath = path;
  }
}
