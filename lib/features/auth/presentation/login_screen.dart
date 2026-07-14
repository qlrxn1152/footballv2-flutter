import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/brand_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_banner.dart';
import 'auth_controller.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authControllerProvider.notifier).login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 34, 22, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppTheme.lime,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.sports_soccer,
                            size: 32,
                            color: AppTheme.navy,
                          ),
                        ),
                        const SizedBox(width: 13),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              BrandConfig.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                              ),
                            ),
                            Text(
                              'FOOTBALL RECORD',
                              style: TextStyle(
                                color: AppTheme.lime,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.7,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 38),
                    Text(
                      BrandConfig.slogan,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      key: const ValueKey('login-form-card'),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 28,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              '로그인',
                              style: TextStyle(
                                color: AppTheme.navy,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text('오늘의 경기를 기록해 볼까요?'),
                            const SizedBox(height: 22),
                            if (authState.errorMessage != null) ...[
                              StatusBanner(message: authState.errorMessage!),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _usernameController,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.username],
                              decoration: const InputDecoration(
                                labelText: '아이디',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: _validateUsername,
                              onChanged: (_) => ref
                                  .read(authControllerProvider.notifier)
                                  .clearError(),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              decoration: InputDecoration(
                                labelText: '비밀번호',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: _validatePassword,
                              onFieldSubmitted: (_) => _login(),
                              onChanged: (_) => ref
                                  .read(authControllerProvider.notifier)
                                  .clearError(),
                            ),
                            const SizedBox(height: 22),
                            FilledButton(
                              onPressed: authState.isSubmitting ? null : _login,
                              child: authState.isSubmitting
                                  ? const SizedBox.square(
                                      dimension: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('로그인'),
                            ),
                            const SizedBox(height: 11),
                            OutlinedButton(
                              onPressed: authState.isSubmitting
                                  ? null
                                  : () {
                                      ref
                                          .read(
                                            authControllerProvider.notifier,
                                          )
                                          .clearError();
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => const SignupScreen(),
                                        ),
                                      );
                                    },
                              child: const Text('회원가입'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LoginFeature(label: 'MATCH'),
                        _LoginFeatureDivider(),
                        _LoginFeature(label: 'RANKING'),
                        _LoginFeatureDivider(),
                        _LoginFeature(label: 'RECORD'),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateUsername(String? value) {
    final length = value?.trim().length ?? 0;
    if (length < 4 || length > 12) return '아이디는 4~12자로 입력하세요.';
    return null;
  }

  String? _validatePassword(String? value) {
    final length = value?.length ?? 0;
    if (length < 4 || length > 30) return '비밀번호는 4~30자로 입력하세요.';
    return null;
  }
}

class _LoginFeature extends StatelessWidget {
  const _LoginFeature({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.62),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _LoginFeatureDivider extends StatelessWidget {
  const _LoginFeatureDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppTheme.lime,
        shape: BoxShape.circle,
      ),
    );
  }
}
