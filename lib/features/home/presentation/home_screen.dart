import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../matches/data/team_match_repository.dart';
import '../../matches/presentation/match_hub_screen.dart';
import '../../members/data/member_repository.dart';
import '../../members/presentation/member_ranking_screen.dart';
import '../../teams/data/team_repository.dart';
import '../../teams/presentation/team_list_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

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
    setState(() => _index = index);
    _refreshTab(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_index],
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () => _refreshTab(_index),
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 18),
            child: Icon(Icons.sports_soccer),
          ),
        ],
      ),
      // 선택된 화면만 마운트해 탭 진입 시 해당 autoDispose provider가
      // 항상 새 API 요청을 시작하도록 합니다.
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: '선수',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: '팀',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_soccer),
            selectedIcon: Icon(Icons.sports_soccer),
            label: '매치',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '내 정보',
          ),
        ],
      ),
    );
  }
}
