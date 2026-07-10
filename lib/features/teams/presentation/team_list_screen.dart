import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                itemCount: items.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _TeamListHeader(
                      teamCount: items.length,
                      onCreate: () => _createTeam(context, ref),
                    );
                  }
                  return _TeamCard(
                    rank: index,
                    team: items[index - 1],
                    onTap: () => _openTeam(
                      context,
                      ref,
                      items[index - 1].teamId,
                    ),
                  );
                },
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TEAM RANKING',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text('팀 레이팅 순 · 총 $teamCount개 팀'),
              ],
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('팀 만들기'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.rank,
    required this.team,
    required this.onTap,
  });

  final int rank;
  final TeamSummary team;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$rank',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.teamName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 12,
                      children: [
                        Text('리더 ${team.leaderUsername}'),
                        Text('팀원 ${team.memberCount}명'),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${team.teamRating}',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text('RATING', style: TextStyle(fontSize: 10)),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

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
