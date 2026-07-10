import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_session.dart';

abstract interface class SessionStore {
  Future<void> save(AuthSession session);
  Future<AuthSession?> read();
  Future<void> clear();
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore([FlutterSecureStorage? storage])
    : _storage = storage ?? FlutterSecureStorage();

  static const _tokenKey = 'access_token';
  static const _tokenTypeKey = 'token_type';
  static const _expiresAtKey = 'expires_at';
  static const _memberIdKey = 'member_id';
  static const _usernameKey = 'username';
  static const _ratingKey = 'member_rating';

  final FlutterSecureStorage _storage;

  @override
  Future<void> save(AuthSession session) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: session.accessToken),
      _storage.write(key: _tokenTypeKey, value: session.tokenType),
      _storage.write(
        key: _expiresAtKey,
        value: session.expiresAt.toIso8601String(),
      ),
      _storage.write(key: _memberIdKey, value: '${session.memberId}'),
      _storage.write(key: _usernameKey, value: session.username),
      _storage.write(key: _ratingKey, value: '${session.memberRating}'),
    ]);
  }

  @override
  Future<AuthSession?> read() async {
    final values = await Future.wait([
      _storage.read(key: _tokenKey),
      _storage.read(key: _tokenTypeKey),
      _storage.read(key: _expiresAtKey),
      _storage.read(key: _memberIdKey),
      _storage.read(key: _usernameKey),
      _storage.read(key: _ratingKey),
    ]);

    if (values.any((value) => value == null)) return null;

    final session = AuthSession(
      accessToken: values[0]!,
      tokenType: values[1]!,
      expiresAt: DateTime.parse(values[2]!),
      memberId: int.parse(values[3]!),
      username: values[4]!,
      memberRating: int.parse(values[5]!),
    );

    if (session.isExpired) {
      await clear();
      return null;
    }

    return session;
  }

  @override
  Future<void> clear() => _storage.deleteAll();
}

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SecureSessionStore(),
);
