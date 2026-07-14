import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/brand_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_screen.dart';

class FootballV2App extends ConsumerWidget {
  const FootballV2App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return MaterialApp(
      title: BrandConfig.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: switch (authState.status) {
        AuthStatus.initializing => const _SplashScreen(),
        AuthStatus.unauthenticated => const LoginScreen(),
        AuthStatus.authenticated => const HomeScreen(),
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.navy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.lime,
                borderRadius: BorderRadius.all(Radius.circular(26)),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Icon(
                  Icons.sports_soccer,
                  color: AppTheme.navy,
                  size: 54,
                ),
              ),
            ),
            SizedBox(height: 22),
            Text(
              BrandConfig.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              BrandConfig.slogan,
              style: TextStyle(color: Color(0xFFBFD1D5)),
            ),
            SizedBox(height: 26),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                color: AppTheme.lime,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
