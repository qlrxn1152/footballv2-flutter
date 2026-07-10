import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../session/session_store.dart';

class ApiClient {
  ApiClient(this._sessionStore)
    : dio = Dio(
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
            // 현재 FootballV2 백엔드는 JWT 인증 필터 완성 전까지 이 헤더를 사용합니다.
            options.headers['X-MEMBER-ID'] = session.memberId;
          }
          handler.next(options);
        },
      ),
    );
  }

  final SessionStore _sessionStore;
  final Dio dio;
}

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(sessionStoreProvider)),
);
