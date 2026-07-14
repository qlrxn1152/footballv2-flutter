import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'daily_visit_summary.dart';

class DailyAnalyticsRepository {
  const DailyAnalyticsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<DailyVisitSummary> fetchDailySummary(String date) {
    return runApi(() async {
      final response = await _apiClient.dio.get<Object?>(
        '/api/admin/analytics/visits/daily',
        queryParameters: {'date': date},
      );
      return DailyVisitSummary.fromJson(jsonMap(response.data));
    });
  }
}

final dailyAnalyticsRepositoryProvider = Provider<DailyAnalyticsRepository>(
  (ref) => DailyAnalyticsRepository(ref.watch(apiClientProvider)),
);

final dailyVisitSummaryProvider = FutureProvider.autoDispose
    .family<DailyVisitSummary, String>(
      (ref, date) => ref
          .watch(dailyAnalyticsRepositoryProvider)
          .fetchDailySummary(date),
    );
