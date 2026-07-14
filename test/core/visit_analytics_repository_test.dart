import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/analytics/visit_analytics_repository.dart';
import 'package:footballv2_flutter/core/analytics/visitor_id_store.dart';
import 'package:footballv2_flutter/core/network/api_client.dart';
import 'package:footballv2_flutter/core/session/auth_session.dart';
import 'package:footballv2_flutter/core/session/session_store.dart';

void main() {
  test('앱 시작 시 APP_OPEN 방문 기록을 전송한다', () async {
    final apiClient = ApiClient(_EmptySessionStore());
    RequestOptions? capturedRequest;
    apiClient.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 201,
              data: {'visitLogId': 1},
            ),
          );
        },
      ),
    );
    final repository = VisitAnalyticsRepository(
      apiClient,
      _FixedVisitorIdStore(),
    );

    await repository.recordAppOpen();

    expect(capturedRequest?.method, 'POST');
    expect(capturedRequest?.path, '/api/analytics/visits');
    expect(capturedRequest?.data, {
      'visitorId': 'visitor-123',
      'path': '/',
      'eventType': 'APP_OPEN',
    });
  });
}

class _FixedVisitorIdStore implements VisitorIdStore {
  @override
  Future<String> getOrCreate() async => 'visitor-123';
}

class _EmptySessionStore implements SessionStore {
  @override
  Future<void> clear() async {}

  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> save(AuthSession session) async {}
}
