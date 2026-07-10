import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/session/auth_session.dart';
import '../data/auth_repository.dart';

enum AuthStatus { initializing, unauthenticated, authenticated }

class AuthState {
  const AuthState._({
    required this.status,
    this.session,
    this.isSubmitting = false,
    this.errorMessage,
  });

  const AuthState.initializing()
    : this._(status: AuthStatus.initializing);

  const AuthState.unauthenticated({
    bool isSubmitting = false,
    String? errorMessage,
  }) : this._(
         status: AuthStatus.unauthenticated,
         isSubmitting: isSubmitting,
         errorMessage: errorMessage,
       );

  const AuthState.authenticated(AuthSession session)
    : this._(status: AuthStatus.authenticated, session: session);

  final AuthStatus status;
  final AuthSession? session;
  final bool isSubmitting;
  final String? errorMessage;
}

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    Future<void>.microtask(_restore);
    return const AuthState.initializing();
  }

  Future<void> _restore() async {
    try {
      final session = await _repository.restoreSession();
      state = session == null
          ? const AuthState.unauthenticated()
          : AuthState.authenticated(session);
    } catch (_) {
      await _repository.logout();
      state = const AuthState.unauthenticated();
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = const AuthState.unauthenticated(isSubmitting: true);
    try {
      final session = await _repository.login(
        username: username,
        password: password,
      );
      state = AuthState.authenticated(session);
      return true;
    } catch (error) {
      state = AuthState.unauthenticated(errorMessage: _message(error));
      return false;
    }
  }

  Future<bool> signupAndLogin({
    required String username,
    required String password,
  }) async {
    state = const AuthState.unauthenticated(isSubmitting: true);
    try {
      await _repository.signup(username: username, password: password);
      final session = await _repository.login(
        username: username,
        password: password,
      );
      state = AuthState.authenticated(session);
      return true;
    } catch (error) {
      state = AuthState.unauthenticated(errorMessage: _message(error));
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState.unauthenticated();
  }

  void clearError() {
    if (state.status == AuthStatus.unauthenticated) {
      state = const AuthState.unauthenticated();
    }
  }

  String _message(Object error) {
    return error is ApiException ? error.message : '알 수 없는 오류가 발생했습니다.';
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
