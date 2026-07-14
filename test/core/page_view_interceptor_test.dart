import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/analytics/visitor_id_store.dart';
import 'package:footballv2_flutter/core/network/api_client.dart';
import 'package:footballv2_flutter/core/session/auth_session.dart';
import 'package:footballv2_flutter/core/session/session_store.dart';

void main() {
  test('일반 API 호출을 PAGE_VIEW로 기록한다', () async {
    final analyticsDio = Dio(BaseOptions(baseUrl: 'http://analytics.test'));
    final recorded = Completer<RequestOptions>();
    analyticsDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          recorded.complete(options);
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 201,
              data: {'visitId': 2},
            ),
          );
        },
      ),
    );
    final apiClient = ApiClient(
      _EmptySessionStore(),
      visitorIdStore: _FixedVisitorIdStore(),
      analyticsDio: analyticsDio,
    );
    _stubBusinessApi(apiClient.dio);

    await apiClient.dio.get<Object?>('/api/teams/3');
    final request = await recorded.future;

    expect(request.path, '/api/analytics/visits');
    expect(request.data, {
      'visitorId': 'visitor-123',
      'path': '/api/teams/3',
      'eventType': 'PAGE_VIEW',
    });
  });

  test('방문 기록 API 자체는 PAGE_VIEW로 다시 기록하지 않는다', () async {
    final analyticsDio = Dio(BaseOptions(baseUrl: 'http://analytics.test'));
    var pageViewCount = 0;
    analyticsDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          pageViewCount++;
          handler.resolve(
            Response<Object?>(requestOptions: options, statusCode: 201),
          );
        },
      ),
    );
    final apiClient = ApiClient(
      _EmptySessionStore(),
      visitorIdStore: _FixedVisitorIdStore(),
      analyticsDio: analyticsDio,
    );
    _stubBusinessApi(apiClient.dio);

    await apiClient.dio.post<Object?>(
      '/api/analytics/visits',
      data: {
        'visitorId': 'visitor-123',
        'path': '/',
        'eventType': 'APP_OPEN',
      },
    );
    await pumpEventQueue();

    expect(pageViewCount, 0);
  });
}

void _stubBusinessApi(Dio dio) {
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response<Object?>(requestOptions: options, statusCode: 200),
        );
      },
    ),
  );
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
