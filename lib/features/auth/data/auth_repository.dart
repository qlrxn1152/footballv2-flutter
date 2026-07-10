import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/auth_session.dart';
import '../../../core/session/session_store.dart';

class AuthRepository {
  const AuthRepository(this._apiClient, this._sessionStore);

  final ApiClient _apiClient;
  final SessionStore _sessionStore;

  Future<void> signup({
    required String username,
    required String password,
  }) {
    return runApi(() async {
      await _apiClient.dio.post<Object?>(
        '/api/auth/signup',
        data: {'username': username, 'password': password},
      );
    });
  }

  Future<AuthSession> login({
    required String username,
    required String password,
  }) {
    return runApi(() async {
      final response = await _apiClient.dio.post<Object?>(
        '/api/auth/login',
        data: {'username': username, 'password': password},
      );
      final session = AuthSession.fromLoginJson(jsonMap(response.data));
      await _sessionStore.save(session);
      return session;
    });
  }

  Future<AuthSession?> restoreSession() => _sessionStore.read();

  Future<void> logout() => _sessionStore.clear();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(sessionStoreProvider),
  ),
);
