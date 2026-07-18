@JS()
library;

import 'dart:js_interop';

import 'push_messaging_client_base.dart';

@JS('footballV2Push.permissionStatus')
external JSString _permissionStatus();

@JS('footballV2Push.requestToken')
external JSPromise<JSString?> _requestToken();

@JS('footballV2Push.currentToken')
external JSPromise<JSString?> _currentToken();

@JS('footballV2Push.deleteToken')
external JSPromise<JSAny?> _deleteToken();

PushMessagingClient createPlatformPushMessagingClient() =>
    const WebPushMessagingClient();

class WebPushMessagingClient implements PushMessagingClient {
  const WebPushMessagingClient();

  @override
  String get platform => 'WEB';

  @override
  Future<PushPermissionStatus> permissionStatus() async {
    try {
      return switch (_permissionStatus().toDart) {
        'authorized' => PushPermissionStatus.authorized,
        'denied' => PushPermissionStatus.denied,
        'not-determined' => PushPermissionStatus.notDetermined,
        'not-configured' => PushPermissionStatus.notConfigured,
        _ => PushPermissionStatus.unsupported,
      };
    } catch (_) {
      return PushPermissionStatus.notConfigured;
    }
  }

  @override
  Future<String?> requestPermissionAndGetToken() async {
    try {
      return (await _requestToken().toDart)?.toDart;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return (await _currentToken().toDart)?.toDart;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      await _deleteToken().toDart;
    } catch (_) {
      // 브라우저가 토큰 삭제를 지원하지 않아도 서버 등록 해제는 계속한다.
    }
  }
}
