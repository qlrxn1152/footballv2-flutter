import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/brand_config.dart';
import '../../analytics/presentation/daily_analytics_screen.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../matches/data/team_match_repository.dart';
import '../../matches/presentation/match_hub_screen.dart';
import '../../members/data/member_repository.dart';
import '../../members/presentation/member_detail_screen.dart';
import '../../members/presentation/member_ranking_screen.dart';
import '../../teams/data/team_repository.dart';
import '../../teams/presentation/team_list_screen.dart';
import 'app_menu_drawer.dart';
import 'home_navigation.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _titles = ['선수 랭킹', '팀', '매치', '내 정보'];
  static const _pages = [
    MemberRankingScreen(),
    TeamListScreen(),
    MatchHubScreen(),
    ProfileScreen(),
  ];

  void _refreshTab(int index) {
    switch (index) {
      case 0:
        ref.invalidate(memberRankingsProvider);
        break;
      case 1:
        ref.invalidate(teamsProvider);
        break;
      case 2:
        for (final status in const ['PENDING', 'MATCHED', 'COMPLETED']) {
          ref.invalidate(teamMatchesProvider(status));
        }
        ref.invalidate(memberMeProvider);
        break;
      case 3:
        ref.invalidate(memberMeProvider);
        ref.invalidate(myTeamJoinRequestsProvider);
        break;
    }
  }

  void _selectTab(int index) {
    ref.read(homeTabIndexProvider.notifier).select(index);
    _refreshTab(index);
  }

  void _closeMenu() {
    Navigator.of(context).pop();
  }

  void _openProfile() {
    _closeMenu();
    _selectTab(3);
  }

  Future<void> _openPage(Widget page) async {
    _closeMenu();
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<void> _showAppInfo() async {
    _closeMenu();
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    showAboutDialog(
      context: context,
      applicationName: BrandConfig.name,
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.sports_soccer, size: 44),
      children: const [Text(BrandConfig.slogan)],
    );
  }

  Future<void> _confirmLogout() async {
    _closeMenu();
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('현재 계정에서 로그아웃할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(homeTabIndexProvider);
    final session = ref.watch(authControllerProvider).session;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[index],
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () => _refreshTab(index),
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
          ),
          Builder(
            builder: (context) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                key: const ValueKey('app-menu-button'),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                tooltip: '전체 메뉴',
                icon: const Icon(Icons.sports_soccer),
              ),
            ),
          ),
        ],
      ),
      // 선택된 화면만 마운트해 탭 진입 시 해당 autoDispose provider가
      // 항상 새 API 요청을 시작하도록 합니다.
      body: _pages[index],
      bottomNavigationBar: FootballNavigationBar(
        selectedIndex: index,
        onDestinationSelected: _selectTab,
      ),
      endDrawer: AppMenuDrawer(
        username: session?.username ?? '회원',
        onOpenProfile: _openProfile,
        onOpenGoals: () {
          final memberId = session?.memberId;
          if (memberId != null) {
            _openPage(MemberDetailScreen(memberId: memberId));
          }
        },
        onOpenAnalytics: () => _openPage(const DailyAnalyticsScreen()),
        onShowAppInfo: _showAppInfo,
        onLogout: _confirmLogout,
      ),
    );
  }
}
