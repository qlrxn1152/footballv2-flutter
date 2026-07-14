import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/page_view_interceptor.dart';
import '../analytics/visitor_id_store.dart';
import '../config/app_config.dart';
import '../session/session_store.dart';

class ApiClient {
  ApiClient(
    this._sessionStore, {
    VisitorIdStore? visitorIdStore,
    Dio? analyticsDio,
  })
    : dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      ),
      _analyticsDio = analyticsDio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              contentType: Headers.jsonContentType,
              responseType: ResponseType.json,
            ),
          ) {
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final session = await _sessionStore.read();
          if (session != null) {
            options.headers['Authorization'] =
                '${session.tokenType} ${session.accessToken}';
          }
          handler.next(options);
        },
      ),
    );
    if (visitorIdStore != null) {
      dio.interceptors.add(
        PageViewInterceptor(visitorIdStore, _analyticsDio),
      );
    }
  }

  final SessionStore _sessionStore;
  final Dio _analyticsDio;
  final Dio dio;
}

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    ref.watch(sessionStoreProvider),
    visitorIdStore: ref.watch(visitorIdStoreProvider),
  ),
);
