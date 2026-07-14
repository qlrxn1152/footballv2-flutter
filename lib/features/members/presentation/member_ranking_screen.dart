import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/football_hero_card.dart';
import '../data/member_ranking.dart';
import '../data/member_repository.dart';
import 'member_detail_screen.dart';

class MemberRankingScreen extends ConsumerWidget {
  const MemberRankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankings = ref.watch(memberRankingsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(memberRankingsProvider);
        await ref.read(memberRankingsProvider.future);
      },
      child: rankings.when(
        loading: () => const _LoadingList(),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(memberRankingsProvider),
        ),
        data: (items) => items.isEmpty
            ? const _EmptyView()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                itemCount: items.length + 1,
                separatorBuilder: (_, index) => SizedBox(
                  height: index == 0 ? 18 : 10,
                ),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const FootballHeroCard(
                      eyebrow: 'PLAYER RANKING',
                      title: '오늘의 선수 랭킹',
                      subtitle: '레이팅이 높은 선수부터 한눈에 확인하세요.',
                      icon: Icons.emoji_events_outlined,
                    );
                  }
                  final member = items[index - 1];
                  return _RankingCard(
                    member: member,
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) =>
                            MemberDetailScreen(memberId: member.memberId),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({required this.member, required this.onTap});

  final MemberRanking member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rankColor = switch (member.rank) {
      1 => const Color(0xFFFFC107),
      2 => const Color(0xFF90A4AE),
      3 => const Color(0xFFB87333),
      _ => colorScheme.primary,
    };

    final isPodium = member.rank <= 3;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: isPodium
            ? [
                BoxShadow(
                  color: rankColor.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ]
            : null,
      ),
      child: Card(
        child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: isPodium
                    ? Icon(Icons.emoji_events, color: rankColor, size: 25)
                    : Text(
                        '${member.rank}',
                        style: const TextStyle(
                          color: AppTheme.fieldGreen,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.username,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      member.teamName ?? '소속 팀 없음',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${member.rating}',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'RATING',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.navySoft,
                size: 20,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 240),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.cloud_off_outlined, size: 54),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 18),
        Center(
          child: FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('다시 시도'),
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 180),
        Icon(Icons.group_outlined, size: 54),
        SizedBox(height: 16),
        Text('등록된 선수가 없습니다.', textAlign: TextAlign.center),
      ],
    );
  }
}
