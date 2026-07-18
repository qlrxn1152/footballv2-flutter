import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifications/data/member_device_token_repository.dart';
import 'push_messaging_client.dart';

class PushNotificationService {
  PushNotificationService(this._client, this._repository);

  final PushMessagingClient _client;
  final MemberDeviceTokenRepositoryContract _repository;

  String? _registeredToken;

  Future<PushPermissionStatus> permissionStatus() =>
      _client.permissionStatus();

  Future<PushPermissionStatus> enable() async {
    final token = await _client.requestPermissionAndGetToken();
    final status = await _client.permissionStatus();
    if (status != PushPermissionStatus.authorized) {
      return status;
    }
    if (token == null) {
      throw StateError('FCM 토큰을 발급받지 못했습니다.');
    }

    await _register(token);
    return PushPermissionStatus.authorized;
  }

  Future<void> syncIfAuthorized() async {
    if (await _client.permissionStatus() !=
        PushPermissionStatus.authorized) {
      return;
    }
    final token = await _client.getToken();
    if (token != null) {
      await _register(token);
    }
  }

  Future<void> unregister() async {
    final token = _registeredToken ?? await _client.getToken();
    if (token != null) {
      await _repository.unregister(token);
    }
    await _client.deleteToken();
    _registeredToken = null;
  }

  Future<void> _register(String token) async {
    await _repository.register(token: token, platform: _client.platform);
    _registeredToken = token;
  }
}

final pushMessagingClientProvider = Provider<PushMessagingClient>(
  (ref) => createPushMessagingClient(),
);

final pushNotificationServiceProvider = Provider<PushNotificationService>(
  (ref) => PushNotificationService(
    ref.watch(pushMessagingClientProvider),
    ref.watch(memberDeviceTokenRepositoryProvider),
  ),
);
