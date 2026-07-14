import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'visitor_id_store.dart';

class PageViewInterceptor extends Interceptor {
  PageViewInterceptor(this._visitorIdStore, this._analyticsDio);

  static const _visitPath = '/api/analytics/visits';

  final VisitorIdStore _visitorIdStore;
  final Dio _analyticsDio;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.uri.path;
    if (path != _visitPath) {
      unawaited(_recordPageView(path));
    }
    handler.next(options);
  }

  Future<void> _recordPageView(String path) async {
    try {
      final visitorId = await _visitorIdStore.getOrCreate();
      await _analyticsDio.post<Object?>(
        _visitPath,
        data: {
          'visitorId': visitorId,
          'path': path.isEmpty ? '/' : path,
          'eventType': 'PAGE_VIEW',
        },
      );
    } catch (error) {
      // 방문 기록 실패가 원래 API 요청과 화면 이동을 막아서는 안 됩니다.
      debugPrint('[FootballV2] PAGE_VIEW 기록 실패: $error');
    }
  }
}
