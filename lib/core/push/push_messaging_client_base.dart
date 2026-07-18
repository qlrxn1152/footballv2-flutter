enum PushPermissionStatus {
  unsupported,
  notConfigured,
  notDetermined,
  denied,
  authorized,
}

abstract interface class PushMessagingClient {
  String get platform;

  Future<PushPermissionStatus> permissionStatus();

  Future<String?> requestPermissionAndGetToken();

  Future<String?> getToken();

  Future<void> deleteToken();
}
