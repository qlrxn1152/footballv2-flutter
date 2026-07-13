import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/session/auth_session.dart';
import 'package:footballv2_flutter/core/session/session_store.dart';

void main() {
  test('세션 항목을 동시에 쓰지 않고 순서대로 저장한다', () async {
    final storage = _TrackingSecureStorage();
    final store = SecureSessionStore(storage);
    final session = AuthSession(
      accessToken: 'access-token',
      tokenType: 'Bearer',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      memberId: 7,
      username: 'player7',
      memberRating: 1500,
    );

    await store.save(session);
    final restored = await store.read();

    expect(storage.maxConcurrentWrites, 1);
    expect(restored?.accessToken, session.accessToken);
    expect(restored?.memberId, session.memberId);
    expect(restored?.username, session.username);
  });
}

class _TrackingSecureStorage extends FlutterSecureStorage {
  _TrackingSecureStorage();

  final Map<String, String> _values = {};
  int _activeWrites = 0;
  int maxConcurrentWrites = 0;

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _activeWrites++;
    if (_activeWrites > maxConcurrentWrites) {
      maxConcurrentWrites = _activeWrites;
    }
    try {
      await Future<void>.delayed(const Duration(milliseconds: 1));
      if (value == null) {
        _values.remove(key);
      } else {
        _values[key] = value;
      }
    } finally {
      _activeWrites--;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _values[key];
}
