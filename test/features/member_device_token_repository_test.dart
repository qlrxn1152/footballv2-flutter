import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/network/api_client.dart';
import 'package:footballv2_flutter/core/session/auth_session.dart';
import 'package:footballv2_flutter/core/session/session_store.dart';
import 'package:footballv2_flutter/features/notifications/data/member_device_token_repository.dart';

void main() {
  test('FCM 웹 토큰을 로그인한 멤버에게 등록하고 해제한다', () async {
    final apiClient = ApiClient(_EmptySessionStore());
    final requests = <RequestOptions>[];
    apiClient.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response<void>(requestOptions: options, statusCode: 204),
          );
        },
      ),
    );
    final repository = MemberDeviceTokenRepository(apiClient);

    await repository.register(token: 'fcm-token', platform: 'WEB');
    await repository.unregister('fcm-token');

    expect(requests[0].method, 'POST');
    expect(requests[0].path, '/api/device-tokens');
    expect(requests[0].data, {'token': 'fcm-token', 'platform': 'WEB'});
    expect(requests[1].method, 'DELETE');
    expect(requests[1].path, '/api/device-tokens');
    expect(requests[1].queryParameters, {'token': 'fcm-token'});
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
