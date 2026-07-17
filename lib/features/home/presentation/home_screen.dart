import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/brand_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../announcements/data/announcement_repository.dart';
import '../../announcements/presentation/announcement_list_screen.dart';
import '../../analytics/presentation/daily_analytics_screen.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../matches/data/team_match_repository.dart';
import '../../matches/presentation/match_hub_screen.dart';
import '../../members/data/member_repository.dart';
import '../../members/presentation/member_detail_screen.dart';
import '../../members/presentation/member_ranking_screen.dart';
import '../../notifications/data/member_notification_repository.dart';
import '../../notifications/presentation/member_notification_screen.dart';
import '../../teams/data/team_repository.dart';
import '../../teams/presentation/team_list_screen.dart';
import '../../team_posts/presentation/team_post_list_screen.dart';
import 'app_menu_drawer.dart';
import 'dashboard_screen.dart';
import 'home_navigation.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _titles = ['홈', '선수 랭킹', '팀', '매치', '내 정보'];

  void _refreshTab(int index) {
    ref.invalidate(unreadNotificationCountProvider);
    switch (index) {
      case 0:
        ref.invalidate(memberMeProvider);
        ref.invalidate(memberRankingsProvider);
        ref.invalidate(teamsProvider);
        ref.invalidate(announcementsProvider);
        for (final status in const ['PENDING', 'MATCHED', 'COMPLETED']) {
          ref.invalidate(teamMatchesProvider(status));
        }
        ref.invalidate(allTeamMatchesProvider);
        break;
      case 1:
        ref.invalidate(memberRankingsProvider);
        break;
      case 2:
        ref.invalidate(teamsProvider);
        break;
      case 3:
        for (final status in const ['PENDING', 'MATCHED', 'COMPLETED']) {
          ref.invalidate(teamMatchesProvider(status));
        }
        ref.invalidate(memberMeProvider);
        break;
      case 4:
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
    _selectTab(4);
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

  Future<void> _openNotifications() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const MemberNotificationScreen()),
    );
    if (!mounted) return;
    ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> _openTeamBoard() async {
    _closeMenu();
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    try {
      final member = await ref.read(memberMeProvider.future);
      if (!mounted) return;
      final teamId = member.teamId;
      if (teamId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('팀에 가입한 뒤 게시판을 이용할 수 있습니다.')),
        );
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => TeamPostListScreen(
            teamId: teamId,
            teamName: member.teamName ?? '내 팀',
            currentMemberId: member.memberId,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내 팀 정보를 확인하지 못했습니다.')),
      );
    }
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
    final isAdmin = ref.watch(memberMeProvider).when(
      data: (member) => member.isAdmin,
      error: (_, _) => false,
      loading: () => false,
    );
    final pages = [
      DashboardScreen(onSelectTab: _selectTab),
      const MemberRankingScreen(),
      const TeamListScreen(),
      const MatchHubScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: AppTheme.navy,
        foregroundColor: Colors.white,
        titleSpacing: 18,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.lime,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.sports_soccer,
                color: AppTheme.navy,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  BrandConfig.name,
                  style: TextStyle(
                    color: AppTheme.lime,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  _titles[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          _NotificationButton(onPressed: _openNotifications),
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
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.lime,
                ),
                icon: const Icon(Icons.sports_soccer),
              ),
            ),
          ),
        ],
      ),
      // 선택된 화면만 마운트해 탭 진입 시 해당 autoDispose provider가
      // 항상 새 API 요청을 시작하도록 합니다.
      body: pages[index],
      bottomNavigationBar: FootballNavigationBar(
        selectedIndex: index,
        onDestinationSelected: _selectTab,
      ),
      endDrawer: AppMenuDrawer(
        username: session?.username ?? '회원',
        isAdmin: isAdmin,
        onOpenProfile: _openProfile,
        onOpenGoals: () {
          final memberId = session?.memberId;
          if (memberId != null) {
            _openPage(MemberDetailScreen(memberId: memberId));
          }
        },
        onOpenTeamBoard: _openTeamBoard,
        onOpenAnnouncements: () => _openPage(
          const AnnouncementListScreen(),
        ),
        onOpenAnalytics: () => _openPage(const DailyAnalyticsScreen()),
        onShowAppInfo: _showAppInfo,
        onLogout: _confirmLogout,
      ),
    );
  }
}

class _NotificationButton extends ConsumerWidget {
  const _NotificationButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadNotificationCountProvider).value ?? 0;

    return IconButton(
      key: const ValueKey('notification-button'),
      onPressed: onPressed,
      tooltip: count > 0 ? '읽지 않은 알림 $count개' : '알림',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (count > 0)
            Positioned(
              right: -9,
              top: -8,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE03131),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.navy, width: 1.5),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
