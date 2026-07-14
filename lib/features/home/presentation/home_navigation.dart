import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';

class HomeTabController extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) {
    if (index < 0 || index > 3 || state == index) return;
    state = index;
  }
}

final homeTabIndexProvider = NotifierProvider<HomeTabController, int>(
  HomeTabController.new,
);

class FootballNavigationBar extends StatelessWidget {
  const FootballNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppTheme.line)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.leaderboard_outlined),
              selectedIcon: Icon(Icons.leaderboard_rounded),
              label: '선수',
            ),
            NavigationDestination(
              icon: Icon(Icons.shield_outlined),
              selectedIcon: Icon(Icons.shield),
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
      ),
    );
  }
}
