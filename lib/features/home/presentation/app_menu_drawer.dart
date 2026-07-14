import 'package:flutter/material.dart';

import '../../../core/config/brand_config.dart';

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
      width: MediaQuery.sizeOf(context).width.clamp(280, 360).toDouble(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.sports_soccer,
                      color: colors.primary,
                      size: 30,
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
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          BrandConfig.slogan,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: '메뉴 닫기',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                '$username님',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
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
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Divider(),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 2, 20, 8),
              child: Text(
                '운영',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, color: foregroundColor),
      title: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
