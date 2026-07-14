import 'package:flutter/material.dart';

import '../../../core/config/brand_config.dart';
import '../../../core/theme/app_theme.dart';

class AppMenuDrawer extends StatelessWidget {
  const AppMenuDrawer({
    required this.username,
    required this.onOpenProfile,
    required this.onOpenGoals,
    required this.onOpenAnalytics,
    required this.onShowAppInfo,
    required this.onLogout,
    super.key,
  });

  final String username;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenGoals;
  final VoidCallback onOpenAnalytics;
  final VoidCallback onShowAppInfo;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: AppTheme.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          bottomLeft: Radius.circular(28),
        ),
      ),
      width: MediaQuery.sizeOf(context).width.clamp(280, 360).toDouble(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 14, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.navy, AppTheme.navySoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.lime,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.sports_soccer,
                          color: AppTheme.navy,
                          size: 29,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              BrandConfig.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              BrandConfig.slogan,
                              style: TextStyle(
                                color: Color(0xFFBFD1D5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        tooltip: '메뉴 닫기',
                        color: Colors.white,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_circle_outlined,
                          color: AppTheme.lime,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$username님',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('나의 풋볼로그', style: _sectionStyle),
            ),
            _MenuTile(
              icon: Icons.person_outline,
              label: '내 정보',
              onTap: onOpenProfile,
            ),
            _MenuTile(
              icon: Icons.sports_soccer_outlined,
              label: '내 득점 기록',
              onTap: onOpenGoals,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text('서비스', style: _sectionStyle),
            ),
            _MenuTile(
              icon: Icons.analytics_outlined,
              label: '일별 사용 통계',
              onTap: onOpenAnalytics,
            ),
            _MenuTile(
              icon: Icons.info_outline,
              label: '앱 정보',
              onTap: onShowAppInfo,
            ),
            const Spacer(),
            const Divider(height: 1),
            _MenuTile(
              icon: Icons.logout,
              label: '로그아웃',
              onTap: onLogout,
              foregroundColor: colors.error,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: (foregroundColor ?? AppTheme.fieldGreen).withValues(
              alpha: 0.1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: foregroundColor ?? AppTheme.fieldGreen),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: foregroundColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}

const _sectionStyle = TextStyle(
  color: Color(0xFF65736D),
  fontSize: 12,
  fontWeight: FontWeight.w900,
  letterSpacing: 0.7,
);
