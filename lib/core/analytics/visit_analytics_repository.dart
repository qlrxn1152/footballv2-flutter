import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'visitor_id_store.dart';

class VisitAnalyticsRepository {
  const VisitAnalyticsRepository(this._apiClient, this._visitorIdStore);

  final ApiClient _apiClient;
  final VisitorIdStore _visitorIdStore;

  Future<void> recordAppOpen({String path = '/'}) {
    return runApi(() async {
      final visitorId = await _visitorIdStore.getOrCreate();
      await _apiClient.dio.post<Object?>(
        '/api/analytics/visits',
        data: {
          'visitorId': visitorId,
          'path': path,
          'eventType': 'APP_OPEN',
        },
      );
    });
  }
}

final visitAnalyticsRepositoryProvider = Provider<VisitAnalyticsRepository>(
  (ref) => VisitAnalyticsRepository(
    ref.watch(apiClientProvider),
    ref.watch(visitorIdStoreProvider),
  ),
);
