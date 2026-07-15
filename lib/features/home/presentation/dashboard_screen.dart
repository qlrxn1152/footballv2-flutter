import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../announcements/data/announcement.dart';
import '../../announcements/data/announcement_repository.dart';
import '../../announcements/presentation/announcement_detail_screen.dart';
import '../../announcements/presentation/announcement_list_screen.dart';
import '../../matches/data/team_match.dart';
import '../../matches/data/team_match_repository.dart';
import '../../matches/presentation/team_match_detail_screen.dart';
import '../../members/data/member_account.dart';
import '../../members/data/member_ranking.dart';
import '../../members/data/member_repository.dart';
import '../../members/presentation/member_detail_screen.dart';
import '../../teams/data/team_models.dart';
import '../../teams/data/team_repository.dart';
import '../../teams/presentation/team_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({required this.onSelectTab, super.key});

  final ValueChanged<int> onSelectTab;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(memberMeProvider);
    ref.invalidate(memberRankingsProvider);
    ref.invalidate(teamsProvider);
    ref.invalidate(announcementsProvider);
    for (final status in const ['PENDING', 'MATCHED', 'COMPLETED']) {
      ref.invalidate(teamMatchesProvider(status));
    }
    ref.invalidate(allTeamMatchesProvider);

    await Future.wait<void>([
      ref.read(memberMeProvider.future).then<void>((_) {}).catchError((_) {}),
      ref
          .read(memberRankingsProvider.future)
          .then<void>((_) {})
          .catchError((_) {}),
      ref.read(teamsProvider.future).then<void>((_) {}).catchError((_) {}),
      ref
          .read(announcementsProvider.future)
          .then<void>((_) {})
          .catchError((_) {}),
      ref
          .read(allTeamMatchesProvider.future)
          .then<void>((_) {})
          .catchError((_) {}),
    ]);
  }

  Future<void> _push(BuildContext context, Widget page) async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(memberMeProvider);
    final matches = ref.watch(allTeamMatchesProvider);
    final members = ref.watch(memberRankingsProvider);
    final teams = ref.watch(teamsProvider);
    final announcements = ref.watch(announcementsProvider);

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView(
        key: const ValueKey('home-dashboard'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        children: [
          _WelcomeCard(
            member: member,
            onOpenProfile: () => onSelectTab(4),
            onOpenTeam: (teamId) => _push(
              context,
              TeamDetailScreen(teamId: teamId),
            ),
          ),
          const SizedBox(height: 22),
          const _SectionTitle(title: '빠른 메뉴', subtitle: '원하는 곳으로 바로 이동하세요'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  key: const ValueKey('dashboard-members-action'),
                  icon: Icons.leaderboard_outlined,
                  label: '선수 순위',
                  color: const Color(0xFF1971C2),
                  onTap: () => onSelectTab(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.shield_outlined,
                  label: '팀 순위',
                  color: AppTheme.fieldGreen,
                  onTap: () => onSelectTab(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.sports_soccer,
                  label: '경기 일정',
                  color: const Color(0xFFF08C00),
                  onTap: () => onSelectTab(3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.campaign_outlined,
                  label: '공지사항',
                  color: const Color(0xFF7950F2),
                  onTap: () => _push(
                    context,
                    const AnnouncementListScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle(
            title: '다가오는 경기',
            subtitle: '가장 가까운 매치 일정',
            onMore: () => onSelectTab(3),
          ),
          const SizedBox(height: 10),
          _UpcomingMatchSection(
            matches: matches,
            onOpenMatch: (matchId) => _push(
              context,
              TeamMatchDetailScreen(teamMatchId: matchId),
            ),
            onOpenMatches: () => onSelectTab(3),
          ),
          const SizedBox(height: 24),
          _SectionTitle(
            title: '오늘의 순위',
            subtitle: '현재 선수와 팀 랭킹',
            onMore: () => onSelectTab(1),
          ),
          const SizedBox(height: 10),
          _RankingOverview(
            members: members,
            teams: teams,
            onOpenMember: (memberId) => _push(
              context,
              MemberDetailScreen(memberId: memberId),
            ),
            onOpenTeam: (teamId) => _push(
              context,
              TeamDetailScreen(teamId: teamId),
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(
            title: '공지사항',
            subtitle: '풋볼로그의 새로운 소식',
            onMore: () => _push(
              context,
              const AnnouncementListScreen(),
            ),
          ),
          const SizedBox(height: 10),
          _AnnouncementPreview(
            announcements: announcements,
            onOpen: (id) => _push(
              context,
              AnnouncementDetailScreen(id: id),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.member,
    required this.onOpenProfile,
    required this.onOpenTeam,
  });

  final AsyncValue<MemberMe> member;
  final VoidCallback onOpenProfile;
  final ValueChanged<int> onOpenTeam;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.navy, AppTheme.navySoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            bottom: -34,
            child: Icon(
              Icons.sports_soccer,
              size: 154,
              color: Colors.white.withValues(alpha: 0.055),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: member.when(
              loading: () => const SizedBox(
                height: 112,
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.lime),
                ),
              ),
              error: (_, _) => _WelcomeFallback(onOpenProfile: onOpenProfile),
              data: (item) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TODAY ON FOOTLOG',
                    style: TextStyle(
                      color: AppTheme.lime,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${item.username}님, 오늘도 뛰어볼까요?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _WelcomePill(
                        icon: Icons.stars_outlined,
                        text: '선수 ${item.memberRating}점',
                        onTap: onOpenProfile,
                      ),
                      if (item.teamId != null)
                        _WelcomePill(
                          icon: Icons.shield_outlined,
                          text: item.teamName ?? '내 팀',
                          onTap: () => onOpenTeam(item.teamId!),
                        )
                      else
                        _WelcomePill(
                          icon: Icons.group_add_outlined,
                          text: '소속 팀 없음',
                          onTap: onOpenProfile,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeFallback extends StatelessWidget {
  const _WelcomeFallback({required this.onOpenProfile});

  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오늘도 풋볼로그와 함께해요',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onOpenProfile,
          style: TextButton.styleFrom(foregroundColor: AppTheme.lime),
          icon: const Icon(Icons.person_outline),
          label: const Text('내 정보 확인'),
        ),
      ],
    );
  }
}

class _WelcomePill extends StatelessWidget {
  const _WelcomePill({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.11),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppTheme.lime),
              const SizedBox(width: 6),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.onMore,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.ink.withValues(alpha: 0.58),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (onMore != null)
          TextButton(
            onPressed: onMore,
            child: const Text('전체 보기'),
          ),
      ],
    );
  }
}

class _UpcomingMatchSection extends StatelessWidget {
  const _UpcomingMatchSection({
    required this.matches,
    required this.onOpenMatch,
    required this.onOpenMatches,
  });

  final AsyncValue<List<TeamMatchSummary>> matches;
  final ValueChanged<int> onOpenMatch;
  final VoidCallback onOpenMatches;

  @override
  Widget build(BuildContext context) {
    return matches.when(
      loading: () => const _SectionLoading(height: 150),
      error: (_, _) => _InlineMessage(
        icon: Icons.cloud_off_outlined,
        message: '경기 일정을 불러오지 못했습니다.',
        actionLabel: '매치 탭으로',
        onAction: onOpenMatches,
      ),
      data: (items) {
        final match = _nextMatch(items);
        if (match == null) {
          return _InlineMessage(
            icon: Icons.event_available_outlined,
            message: '예정된 경기가 없습니다.',
            actionLabel: '매치 확인',
            onAction: onOpenMatches,
          );
        }
        return _UpcomingMatchCard(
          match: match,
          onTap: () => onOpenMatch(match.teamMatchId),
        );
      },
    );
  }
}

class _UpcomingMatchCard extends StatelessWidget {
  const _UpcomingMatchCard({required this.match, required this.onTap});

  final TeamMatchSummary match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final opponent = match.awayTeamName ?? '상대 팀 대기 중';
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lime,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      match.isPending ? '상대 대기' : '매칭 완료',
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatMatchDate(match.playedAt),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _TeamName(
                      label: 'HOME',
                      name: match.homeTeamName,
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.canvas,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Expanded(
                    child: _TeamName(
                      label: 'AWAY',
                      name: opponent,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamName extends StatelessWidget {
  const _TeamName({
    required this.label,
    required this.name,
    this.alignEnd = false,
  });

  final String label;
  final String name;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.fieldGreen,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _RankingOverview extends StatelessWidget {
  const _RankingOverview({
    required this.members,
    required this.teams,
    required this.onOpenMember,
    required this.onOpenTeam,
  });

  final AsyncValue<List<MemberRanking>> members;
  final AsyncValue<List<TeamSummary>> teams;
  final ValueChanged<int> onOpenMember;
  final ValueChanged<int> onOpenTeam;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _RankingCard<MemberRanking>(
            title: '선수 TOP 3',
            icon: Icons.person_outline,
            value: members,
            nameOf: (item) => item.username,
            scoreOf: (item) => '${item.rating}',
            onTap: (item) => onOpenMember(item.memberId),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RankingCard<TeamSummary>(
            title: '팀 TOP 3',
            icon: Icons.shield_outlined,
            value: teams,
            nameOf: (item) => item.teamName,
            scoreOf: (item) => '${item.teamRating}',
            onTap: (item) => onOpenTeam(item.teamId),
          ),
        ),
      ],
    );
  }
}

class _RankingCard<T> extends StatelessWidget {
  const _RankingCard({
    required this.title,
    required this.icon,
    required this.value,
    required this.nameOf,
    required this.scoreOf,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final AsyncValue<List<T>> value;
  final String Function(T item) nameOf;
  final String Function(T item) scoreOf;
  final ValueChanged<T> onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 19, color: AppTheme.fieldGreen),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            value.when(
              loading: () => const SizedBox(
                height: 94,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const SizedBox(
                height: 94,
                child: Center(child: Text('순위 로딩 실패')),
              ),
              data: (items) {
                final top = items.take(3).toList(growable: false);
                if (top.isEmpty) {
                  return const SizedBox(
                    height: 94,
                    child: Center(child: Text('순위 없음')),
                  );
                }
                return Column(
                  children: [
                    for (var index = 0; index < top.length; index++)
                      InkWell(
                        onTap: () => onTap(top[index]),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 22,
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: index == 0
                                        ? AppTheme.fieldGreen
                                        : AppTheme.ink.withValues(alpha: 0.55),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  nameOf(top[index]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                scoreOf(top[index]),
                                style: const TextStyle(
                                  color: AppTheme.fieldGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementPreview extends StatelessWidget {
  const _AnnouncementPreview({
    required this.announcements,
    required this.onOpen,
  });

  final AsyncValue<List<AnnouncementSummary>> announcements;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    return announcements.when(
      loading: () => const _SectionLoading(height: 110),
      error: (_, _) => const _InlineMessage(
        icon: Icons.notifications_off_outlined,
        message: '공지사항을 불러오지 못했습니다.',
      ),
      data: (items) {
        if (items.isEmpty) {
          return const _InlineMessage(
            icon: Icons.notifications_none,
            message: '등록된 공지사항이 없습니다.',
          );
        }
        return Card(
          child: Column(
            children: [
              for (var index = 0; index < items.take(2).length; index++) ...[
                _AnnouncementTile(
                  item: items[index],
                  onTap: () => onOpen(items[index].announcementId),
                ),
                if (index < items.take(2).length - 1)
                  const Divider(height: 1),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.item, required this.onTap});

  final AnnouncementSummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: _announcementColor(item.type).withValues(alpha: 0.1),
        foregroundColor: _announcementColor(item.type),
        child: Icon(item.pinned ? Icons.push_pin : Icons.campaign_outlined),
      ),
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text('${item.type.label} · ${item.authorUsername}'),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.fieldGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}

TeamMatchSummary? _nextMatch(List<TeamMatchSummary> matches) {
  final active = matches
      .where((match) => !match.isCompleted)
      .toList(growable: false);
  if (active.isEmpty) return null;

  final now = DateTime.now();
  final upcoming = active
      .where((match) => match.playedAt != null && !match.playedAt!.isBefore(now))
      .toList();
  upcoming.sort((a, b) => a.playedAt!.compareTo(b.playedAt!));
  if (upcoming.isNotEmpty) return upcoming.first;

  final dated = active.where((match) => match.playedAt != null).toList();
  dated.sort((a, b) => b.playedAt!.compareTo(a.playedAt!));
  return dated.isNotEmpty ? dated.first : active.first;
}

String _formatMatchDate(DateTime? value) {
  if (value == null) return '일정 미정';
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$month.$day $hour:$minute';
}

Color _announcementColor(AnnouncementType type) {
  return switch (type) {
    AnnouncementType.notice => const Color(0xFF1971C2),
    AnnouncementType.update => AppTheme.fieldGreen,
    AnnouncementType.maintenance => const Color(0xFFF08C00),
  };
}
