import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/football_hero_card.dart';
import '../data/team_models.dart';
import '../data/team_repository.dart';
import 'create_team_screen.dart';
import 'team_detail_screen.dart';

class TeamListScreen extends ConsumerWidget {
  const TeamListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = ref.watch(teamsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(teamsProvider);
        await ref.read(teamsProvider.future);
      },
      child: teams.when(
        loading: () => const _LoadingView(),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(teamsProvider),
        ),
        data: (items) => items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  _TeamListHeader(
                    teamCount: 0,
                    onCreate: () => _createTeam(context, ref),
                  ),
                  const SizedBox(height: 18),
                  const _EmptyTeamCard(),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  _TeamListHeader(
                    teamCount: items.length,
                    onCreate: () => _createTeam(context, ref),
                  ),
                  const SizedBox(height: 18),
                  _TeamRankingTable(
                    teams: items,
                    onOpenTeam: (teamId) => _openTeam(context, ref, teamId),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _createTeam(BuildContext context, WidgetRef ref) async {
    final teamId = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const CreateTeamScreen()),
    );
    if (teamId == null || !context.mounted) return;
    ref.invalidate(teamsProvider);
    await _openTeam(context, ref, teamId);
  }

  Future<void> _openTeam(
    BuildContext context,
    WidgetRef ref,
    int teamId,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => TeamDetailScreen(teamId: teamId)),
    );
    if (context.mounted) ref.invalidate(teamsProvider);
  }
}

class _TeamListHeader extends StatelessWidget {
  const _TeamListHeader({required this.teamCount, required this.onCreate});

  final int teamCount;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return FootballHeroCard(
      eyebrow: 'TEAM RANKING',
      title: '우리 팀의 현재 순위',
      subtitle: '팀 레이팅 순 · 총 $teamCount개 팀',
      icon: Icons.shield_outlined,
      content: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('팀 만들기'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.lime,
              foregroundColor: AppTheme.navy,
              minimumSize: const Size(0, 48),
            ),
          ),
      ),
    );
  }
}

class _TeamRankingTable extends StatelessWidget {
  const _TeamRankingTable({required this.teams, required this.onOpenTeam});

  final List<TeamSummary> teams;
  final ValueChanged<int> onOpenTeam;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            color: const Color(0xFFE9EFEC),
            child: const Row(
              children: [
                SizedBox(width: 42, child: Text('순위', style: _tableHeaderStyle)),
                Expanded(child: Text('팀', style: _tableHeaderStyle)),
                SizedBox(
                  width: 64,
                  child: Text(
                    '레이팅',
                    textAlign: TextAlign.center,
                    style: _tableHeaderStyle,
                  ),
                ),
                SizedBox(
                  width: 42,
                  child: Text(
                    '인원',
                    textAlign: TextAlign.center,
                    style: _tableHeaderStyle,
                  ),
                ),
                SizedBox(width: 18),
              ],
            ),
          ),
          for (var index = 0; index < teams.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            _TeamRankingRow(
              rank: index + 1,
              team: teams[index],
              onTap: () => onOpenTeam(teams[index].teamId),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeamRankingRow extends StatelessWidget {
  const _TeamRankingRow({
    required this.rank,
    required this.team,
    required this.onTap,
  });

  final int rank;
  final TeamSummary team;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rankColor = switch (rank) {
      1 => const Color(0xFFFFB000),
      2 => const Color(0xFF78909C),
      3 => const Color(0xFFB56E3B),
      _ => AppTheme.line,
    };

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: rank <= 3
              ? rankColor.withValues(alpha: 0.045)
              : Colors.white,
          border: Border(left: BorderSide(color: rankColor, width: 4)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 38,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: rank <= 3 ? rankColor : AppTheme.navySoft,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: rankColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.shield, color: rankColor, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    team.teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '리더 ${team.leaderUsername}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 64,
              child: Text(
                '${team.teamRating}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.fieldGreen,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(
              width: 42,
              child: Text(
                '${team.memberCount}명',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppTheme.navySoft),
          ],
        ),
      ),
    );
  }
}

const _tableHeaderStyle = TextStyle(
  color: Color(0xFF65736D),
  fontSize: 11,
  fontWeight: FontWeight.w900,
);

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 220),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _EmptyTeamCard extends StatelessWidget {
  const _EmptyTeamCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 22, vertical: 34),
        child: Column(
          children: [
            Icon(Icons.groups_outlined, size: 52),
            SizedBox(height: 14),
            Text(
              '등록된 팀이 없습니다.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 5),
            Text('첫 번째 팀을 만들어 보세요.'),
          ],
        ),
      ),
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
        const Text(
          'GET /api/teams 호출 또는 응답 변환에 실패했습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
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
