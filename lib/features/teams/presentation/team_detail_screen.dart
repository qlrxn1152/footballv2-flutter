import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../members/data/member_repository.dart';
import '../data/team_models.dart';
import '../data/team_repository.dart';
import 'team_join_requests_screen.dart';
import 'team_leader_transfer_screen.dart';
import 'team_settings_screen.dart';

class TeamDetailScreen extends ConsumerStatefulWidget {
  const TeamDetailScreen({required this.teamId, super.key});

  final int teamId;

  @override
  ConsumerState<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends ConsumerState<TeamDetailScreen> {
  bool _joining = false;

  Future<void> _refresh() async {
    ref.invalidate(teamDetailProvider(widget.teamId));
    ref.invalidate(teamMembersProvider(widget.teamId));
    ref.invalidate(myTeamJoinRequestsProvider);
    await Future.wait([
      ref.read(teamDetailProvider(widget.teamId).future),
      ref.read(teamMembersProvider(widget.teamId).future),
    ]);
  }

  Future<void> _requestJoin() async {
    setState(() => _joining = true);
    try {
      await ref.read(teamRepositoryProvider).requestJoin(widget.teamId);
      if (!mounted) return;
      ref.invalidate(myTeamJoinRequestsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('팀 가입 신청을 보냈습니다.')),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : '가입 신청을 보내지 못했습니다.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _openLeaderTransfer(TeamDetail team) async {
    final result = await Navigator.of(context).push<TeamLeaderTransferResult>(
      MaterialPageRoute(
        builder: (_) => TeamLeaderTransferScreen(
          teamId: team.teamId,
          teamName: team.teamName,
        ),
      ),
    );
    if (result == null || !mounted) return;

    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${result.newLeaderUsername}님에게 팀장 권한을 위임했습니다.',
        ),
      ),
    );
  }

  Future<void> _openTeamSettings(TeamDetail team, int memberCount) async {
    final outcome = await Navigator.of(context).push<TeamSettingsOutcome>(
      MaterialPageRoute(
        builder: (_) => TeamSettingsScreen(
          teamId: team.teamId,
          teamName: team.teamName,
          memberCount: memberCount,
        ),
      ),
    );
    if (outcome == null || !mounted) return;

    if (outcome.disbanded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${outcome.teamName} 팀을 해체했습니다.')),
      );
      Navigator.of(context).pop();
      return;
    }

    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('팀 이름을 ${outcome.teamName}(으)로 변경했습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(teamDetailProvider(widget.teamId));
    final members = ref.watch(teamMembersProvider(widget.teamId));
    final myProfile = ref.watch(memberMeProvider);
    final myJoinRequests = ref.watch(myTeamJoinRequestsProvider);
    final memberId = ref.watch(authControllerProvider).session!.memberId;

    return Scaffold(
      appBar: AppBar(title: const Text('팀 상세')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: detail.when(
          loading: () => const _PageLoading(),
          error: (error, _) => _PageError(
            message: error.toString(),
            onRetry: _refresh,
          ),
          data: (team) => members.when(
            loading: () => const _PageLoading(),
            error: (error, _) => _PageError(
              message: error.toString(),
              onRetry: _refresh,
            ),
            data: (teamMembers) {
              final isLeader = team.leaderMemberId == memberId;
              final isMember = teamMembers.any(
                (member) => member.memberId == memberId,
              );
              final belongsToAnotherTeam = myProfile.when(
                data: (member) =>
                    member.hasTeam && member.teamId != widget.teamId,
                loading: () => false,
                error: (_, _) => false,
              );
              final hasPendingRequest = myJoinRequests.when(
                data: (requests) => requests.any(
                  (request) => request.teamId == widget.teamId,
                ),
                loading: () => false,
                error: (_, _) => false,
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _TeamHero(team: team),
                  const SizedBox(height: 14),
                  if (isLeader)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => TeamJoinRequestsScreen(
                                teamId: team.teamId,
                                teamName: team.teamName,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.mark_email_unread_outlined),
                          label: const Text('가입 신청 관리'),
                        ),
                        const SizedBox(height: 9),
                        OutlinedButton.icon(
                          onPressed: () => _openLeaderTransfer(team),
                          icon: const Icon(Icons.manage_accounts_outlined),
                          label: const Text('팀장 위임'),
                        ),
                        const SizedBox(height: 9),
                        OutlinedButton.icon(
                          onPressed: () => _openTeamSettings(
                            team,
                            teamMembers.length,
                          ),
                          icon: const Icon(Icons.settings_outlined),
                          label: const Text('팀 설정'),
                        ),
                      ],
                    )
                  else if (isMember)
                    const _MembershipBanner()
                  else if (belongsToAnotherTeam)
                    const _OtherTeamBanner()
                  else if (hasPendingRequest)
                    const _PendingJoinBanner()
                  else
                    FilledButton.icon(
                      onPressed: _joining ? null : _requestJoin,
                      icon: _joining
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_add_alt_1),
                      label: const Text('팀 가입 신청'),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        '팀원',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Text('${teamMembers.length}명'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (teamMembers.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('등록된 팀원이 없습니다.'),
                      ),
                    )
                  else
                    ...teamMembers.map(
                      (member) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _MemberCard(member: member),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TeamHero extends StatelessWidget {
  const _TeamHero({required this.team});

  final TeamDetail team;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF087F5B), Color(0xFF0CA678)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          Text(
            team.teamName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '리더 ${team.leaderUsername}',
            style: const TextStyle(color: Color(0xFFD3F9D8)),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _HeroMetric(label: 'RATING', value: '${team.teamRating}'),
              const SizedBox(width: 28),
              _HeroMetric(label: 'MEMBERS', value: '${team.memberCount}'),
              const Spacer(),
              Text(
                _formatDate(team.createdAt),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';
    return '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')} 창단';
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});

  final TeamMember member;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: member.isLeader
                  ? const Color(0xFFFFF3BF)
                  : Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                member.isLeader ? Icons.workspace_premium : Icons.person,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.username,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(member.isLeader ? 'LEADER' : 'MEMBER'),
                ],
              ),
            ),
            Text(
              '${member.memberRating}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembershipBanner extends StatelessWidget {
  const _MembershipBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_outlined),
          SizedBox(width: 10),
          Text('현재 소속된 팀입니다.', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PendingJoinBanner extends StatelessWidget {
  const _PendingJoinBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3BF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.schedule_send_outlined),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '가입 승인을 기다리고 있습니다.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtherTeamBanner extends StatelessWidget {
  const _OtherTeamBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '다른 팀에 소속되어 있어 가입을 신청할 수 없습니다.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageLoading extends StatelessWidget {
  const _PageLoading();

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

class _PageError extends StatelessWidget {
  const _PageError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.error_outline, size: 54),
        const SizedBox(height: 14),
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
