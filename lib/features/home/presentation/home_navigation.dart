import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';

class HomeTabController extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) {
    if (index < 0 || index > 4 || state == index) return;
    state = index;
  }
}

final homeTabIndexProvider = NotifierProvider<HomeTabController, int>(
  HomeTabController.new,
);

class FootballPageShell extends StatelessWidget {
  const FootballPageShell({
    required this.child,
    this.selectedIndex,
    super.key,
  });

  final Widget child;
  final int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: FootballPageNavigationBar(
        selectedIndex: selectedIndex,
      ),
    );
  }
}

class FootballPageNavigationBar extends ConsumerWidget {
  const FootballPageNavigationBar({this.selectedIndex, super.key});

  final int? selectedIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestedIndex = selectedIndex;
    final int currentIndex;
    if (requestedIndex case final int index) {
      currentIndex = index;
    } else {
      currentIndex = ref.watch(homeTabIndexProvider);
    }

    return FootballNavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        ref.read(homeTabIndexProvider.notifier).select(index);
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }
}

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
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: '홈',
            ),
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
