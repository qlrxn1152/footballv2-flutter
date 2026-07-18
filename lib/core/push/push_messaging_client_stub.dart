import 'push_messaging_client_base.dart';

PushMessagingClient createPlatformPushMessagingClient() =>
    const UnsupportedPushMessagingClient();

class UnsupportedPushMessagingClient implements PushMessagingClient {
  const UnsupportedPushMessagingClient();

  @override
  String get platform => 'UNKNOWN';

  @override
  Future<PushPermissionStatus> permissionStatus() async =>
      PushPermissionStatus.unsupported;

  @override
  Future<String?> requestPermissionAndGetToken() async => null;

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> deleteToken() async {}
}
