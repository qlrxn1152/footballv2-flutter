enum PushPermissionStatus {
  unsupported,
  notConfigured,
  notDetermined,
  denied,
  authorized,
}

class PushMessagingException implements Exception {
  const PushMessagingException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class PushMessagingClient {
  String get platform;

  Future<PushPermissionStatus> permissionStatus();

  Future<String?> requestPermissionAndGetToken();

  Future<String?> getToken();

  Future<void> deleteToken();
}
