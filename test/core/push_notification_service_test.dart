import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/push/push_messaging_client.dart';
import 'package:footballv2_flutter/core/push/push_notification_service.dart';
import 'package:footballv2_flutter/features/notifications/data/member_device_token_repository.dart';

void main() {
  test('알림 권한 승인 후 FCM 토큰을 서버에 등록한다', () async {
    final client = _FakePushMessagingClient();
    final repository = _FakeDeviceTokenRepository();
    final service = PushNotificationService(client, repository);

    final status = await service.enable();

    expect(status, PushPermissionStatus.authorized);
    expect(repository.registeredToken, 'fcm-token');
    expect(repository.registeredPlatform, 'WEB');
  });

  test('이미 승인된 사용자는 앱 진입 시 최신 FCM 토큰을 다시 동기화한다', () async {
    final client = _FakePushMessagingClient();
    final repository = _FakeDeviceTokenRepository();
    final service = PushNotificationService(client, repository);

    final registered = await service.syncIfAuthorized();

    expect(registered, isTrue);
    expect(repository.registeredToken, 'fcm-token');
  });

  test('승인된 권한이 있어도 FCM 토큰이 없으면 등록되지 않은 상태로 판단한다', () async {
    final client = _FakePushMessagingClient(token: null);
    final repository = _FakeDeviceTokenRepository();
    final service = PushNotificationService(client, repository);

    final registered = await service.syncIfAuthorized();

    expect(registered, isFalse);
    expect(repository.registeredToken, isNull);
  });

  test('로그아웃할 때 서버 등록과 브라우저 FCM 토큰을 해제한다', () async {
    final client = _FakePushMessagingClient();
    final repository = _FakeDeviceTokenRepository();
    final service = PushNotificationService(client, repository);

    await service.syncIfAuthorized();
    await service.unregister();

    expect(repository.unregisteredToken, 'fcm-token');
    expect(client.deleted, isTrue);
  });
}

class _FakePushMessagingClient implements PushMessagingClient {
  _FakePushMessagingClient({this.token = 'fcm-token'});

  final String? token;
  bool deleted = false;

  @override
  String get platform => 'WEB';

  @override
  Future<void> deleteToken() async => deleted = true;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<PushPermissionStatus> permissionStatus() async =>
      PushPermissionStatus.authorized;

  @override
  Future<String?> requestPermissionAndGetToken() async => token;
}

class _FakeDeviceTokenRepository
    implements MemberDeviceTokenRepositoryContract {
  String? registeredToken;
  String? registeredPlatform;
  String? unregisteredToken;

  @override
  Future<void> register({required String token, required String platform}) async {
    registeredToken = token;
    registeredPlatform = platform;
  }

  @override
  Future<void> unregister(String token) async {
    unregisteredToken = token;
  }
}
