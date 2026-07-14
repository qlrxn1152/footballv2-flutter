import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'visit_analytics_repository.dart';

class AppVisitTracker extends ConsumerStatefulWidget {
  const AppVisitTracker({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppVisitTracker> createState() => _AppVisitTrackerState();
}

class _AppVisitTrackerState extends ConsumerState<AppVisitTracker> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_recordAppOpen);
  }

  Future<void> _recordAppOpen() async {
    try {
      await ref.read(visitAnalyticsRepositoryProvider).recordAppOpen();
    } catch (error, stackTrace) {
      // 분석 서버 장애가 로그인이나 앱 화면 진입을 막아서는 안 됩니다.
      debugPrint('[FootballV2] APP_OPEN 기록 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
