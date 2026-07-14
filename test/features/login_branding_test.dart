import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/config/brand_config.dart';
import 'package:footballv2_flutter/core/session/auth_session.dart';
import 'package:footballv2_flutter/features/auth/data/auth_repository.dart';
import 'package:footballv2_flutter/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('로그인 화면에 풋볼로그 대표 문구만 표시한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(BrandConfig.slogan), findsOneWidget);
    expect(find.text('다시 경기장으로'), findsNothing);
    expect(
      find.text('FootballV2에서 팀과 선수 랭킹을 확인하세요.'),
      findsNothing,
    );
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<void> signup({
    required String username,
    required String password,
  }) {
    throw UnimplementedError();
  }
}
