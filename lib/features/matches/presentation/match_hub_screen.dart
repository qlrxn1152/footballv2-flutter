import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../members/data/member_account.dart';
import '../../members/data/member_repository.dart';
import '../../teams/data/team_repository.dart';
import '../data/team_match.dart';
import '../data/team_match_repository.dart';
import 'team_match_create_screen.dart';

enum _MatchStatusTab { pending, matched, completed }

class MatchHubScreen extends ConsumerStatefulWidget {
  const MatchHubScreen({super.key});

  @override
  ConsumerState<MatchHubScreen> createState() => _MatchHubScreenState();
}

class _MatchHubScreenState extends ConsumerState<MatchHubScreen> {
  _MatchStatusTab _status = _MatchStatusTab.pending;
  bool _openingRegistration = false;

  Future<void> _refreshPending() async {
    ref.invalidate(pendingTeamMatchesProvider);
    await ref.read(pendingTeamMatchesProvider.future);
  }

  Future<void> _openRegistration() async {
    setState(() => _openingRegistration = true);
    try {
      final member = await ref.read(memberMeProvider.future);
      final teamId = member.teamId;
      if (teamId == null || !member.isTeamLeader) {
        throw const ApiException('소속 팀의 팀장만 매치를 등록할 수 있습니다.');
      }

      final team = await ref.read(teamDetailProvider(teamId).future);
      if (!mounted) return;
      final result = await Navigator.of(context).push<TeamMatchCreateResult>(
        MaterialPageRoute(
          builder: (_) => TeamMatchCreateScreen(
            teamId: team.teamId,
            teamName: team.teamName,
            teamRating: team.teamRating,
          ),
        ),
      );
      if (result == null || !mounted) return;

      ref.invalidate(pendingTeamMatchesProvider);
      setState(() => _status = _MatchStatusTab.pending);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('매치를 등록했습니다. 상대 팀을 기다립니다.')),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : '매치 등록 화면을 열지 못했습니다.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _openingRegistration = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(memberMeProvider);
    final pendingMatches = ref.watch(pendingTeamMatchesProvider);

    final hasOwnPendingMatch = _hasOwnPendingMatch(member, pendingMatches);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: _MatchHeader(
            member: member,
            hasOwnPendingMatch: hasOwnPendingMatch,
            openingRegistration: _openingRegistration,
            onRegister: _openRegistration,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: SegmentedButton<_MatchStatusTab>(
            segments: const [
              ButtonSegment(
                value: _MatchStatusTab.pending,
                icon: Icon(Icons.hourglass_top_outlined),
                label: Text('대기'),
              ),
              ButtonSegment(
                value: _MatchStatusTab.matched,
                icon: Icon(Icons.handshake_outlined),
                label: Text('매칭'),
              ),
              ButtonSegment(
                value: _MatchStatusTab.completed,
                icon: Icon(Icons.emoji_events_outlined),
                label: Text('완료'),
              ),
            ],
            selected: {_status},
            onSelectionChanged: (selected) {
              setState(() => _status = selected.first);
            },
          ),
        ),
        Expanded(
          child: switch (_status) {
            _MatchStatusTab.pending => _PendingMatchesView(
                matches: pendingMatches,
                onRefresh: _refreshPending,
              ),
            _MatchStatusTab.matched => const _UnavailableStatusView(
                status: 'MATCHED',
                icon: Icons.handshake_outlined,
              ),
            _MatchStatusTab.completed => const _UnavailableStatusView(
                status: 'COMPLETED',
                icon: Icons.emoji_events_outlined,
              ),
          },
        ),
      ],
    );
  }

  bool _hasOwnPendingMatch(
    AsyncValue<MemberMe> member,
    AsyncValue<List<PendingTeamMatch>> matches,
  ) {
    final teamId = member.when(
      data: (item) => item.teamId,
      loading: () => null,
      error: (_, _) => null,
    );
    if (teamId == null) return false;
    return matches.when(
      data: (items) => items.any((match) => match.homeTeamId == teamId),
      loading: () => false,
      error: (_, _) => false,
    );
  }
}

class _MatchHeader extends StatelessWidget {
  const _MatchHeader({
    required this.member,
    required this.hasOwnPendingMatch,
    required this.openingRegistration,
    required this.onRegister,
  });

  final AsyncValue<MemberMe> member;
  final bool hasOwnPendingMatch;
  final bool openingRegistration;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final (buttonLabel, canRegister) = member.when(
      data: (item) {
        if (!item.hasTeam) return ('팀 가입 후 등록 가능', false);
        if (!item.isTeamLeader) return ('팀장만 등록 가능', false);
        if (hasOwnPendingMatch) return ('등록한 매치 대기 중', false);
        return ('새 매치 등록', true);
      },
      loading: () => ('내 팀 확인 중', false),
      error: (_, _) => ('내 팀 확인 실패', false),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF087F5B), Color(0xFF0CA678)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.sports_soccer, color: Colors.white, size: 30),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TEAM MATCH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '매치를 확인하고 새로운 상대를 기다리세요.',
                      style: TextStyle(color: Color(0xFFD3F9D8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: canRegister && !openingRegistration ? onRegister : null,
            icon: openingRegistration
                ? const SizedBox.square(
                    dimension: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_circle_outline),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _PendingMatchesView extends StatelessWidget {
  const _PendingMatchesView({required this.matches, required this.onRefresh});

  final AsyncValue<List<PendingTeamMatch>> matches;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: matches.when(
        loading: () => const _LoadingList(),
        error: (error, _) => _MatchErrorView(
          message: error.toString(),
          onRetry: onRefresh,
        ),
        data: (items) => items.isEmpty
            ? const _EmptyMatchesView()
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final match = items[index];
                  return _PendingMatchCard(match: match);
                },
              ),
      ),
    );
  }
}

class _PendingMatchCard extends StatelessWidget {
  const _PendingMatchCard({required this.match});

  final PendingTeamMatch match;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  child: const Icon(Icons.shield_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.homeTeamName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text('TEAM RATING ${match.homeTeamRating}'),
                    ],
                  ),
                ),
                const _PendingChip(),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  '매치 #${match.teamMatchId}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(_formatDateTime(match.createdAt)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingChip extends StatelessWidget {
  const _PendingChip();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFF08C00);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'PENDING',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _UnavailableStatusView extends StatelessWidget {
  const _UnavailableStatusView({required this.status, required this.icon});

  final String status;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 70),
        Icon(icon, size: 56),
        const SizedBox(height: 16),
        Text(
          '$status 매치 조회 API 준비 중',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 7),
        const Text(
          '백엔드 조회 기능이 추가되면 이 탭에 바로 연결됩니다.',
          textAlign: TextAlign.center,
        ),
      ],
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
        SizedBox(height: 120),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _EmptyMatchesView extends StatelessWidget {
  const _EmptyMatchesView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: const [
        SizedBox(height: 70),
        Icon(Icons.sports_soccer, size: 56),
        SizedBox(height: 15),
        Text(
          '대기 중인 매치가 없습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _MatchErrorView extends StatelessWidget {
  const _MatchErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 70),
        const Icon(Icons.cloud_off_outlined, size: 54),
        const SizedBox(height: 14),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
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

String _formatDateTime(DateTime? value) {
  if (value == null) return '-';
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$month.$day $hour:$minute';
}
