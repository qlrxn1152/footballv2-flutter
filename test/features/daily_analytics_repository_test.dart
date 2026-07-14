import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/network/api_client.dart';
import 'package:footballv2_flutter/core/session/auth_session.dart';
import 'package:footballv2_flutter/core/session/session_store.dart';
import 'package:footballv2_flutter/features/analytics/data/daily_analytics_repository.dart';

void main() {
  test('선택한 날짜를 쿼리 파라미터로 전송한다', () async {
    final apiClient = ApiClient(_EmptySessionStore());
    RequestOptions? capturedRequest;
    apiClient.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'date': '2026-07-14',
                'uniqueVisitors': 8,
                'pageViews': 37,
              },
            ),
          );
        },
      ),
    );
    final repository = DailyAnalyticsRepository(apiClient);

    final summary = await repository.fetchDailySummary('2026-07-14');

    expect(capturedRequest?.method, 'GET');
    expect(
      capturedRequest?.path,
      '/api/admin/analytics/visits/daily',
    );
    expect(capturedRequest?.queryParameters, {'date': '2026-07-14'});
    expect(summary.uniqueVisitors, 8);
    expect(summary.pageViews, 37);
  });
}

class _EmptySessionStore implements SessionStore {
  @override
  Future<void> clear() async {}

  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> save(AuthSession session) async {}
}
