import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../members/data/member_account.dart';
import '../../members/data/member_repository.dart';
import '../../teams/data/team_repository.dart';
import '../../teams/presentation/team_detail_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final Set<int> _cancelingRequestIds = {};
  bool _leavingTeam = false;

  Future<void> _refresh() async {
    ref.invalidate(memberMeProvider);
    final member = await ref.read(memberMeProvider.future);
    if (!member.hasTeam) {
      ref.invalidate(myTeamJoinRequestsProvider);
      await ref.read(myTeamJoinRequestsProvider.future);
    }
  }

  Future<void> _cancelRequest(MyTeamJoinRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('가입 신청 취소'),
        content: Text('${request.teamName} 가입 신청을 취소할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('돌아가기'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('신청 취소'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelingRequestIds.add(request.teamJoinRequestId));
    try {
      await ref
          .read(memberRepositoryProvider)
          .cancelMyTeamJoinRequest(request.teamJoinRequestId);
      if (!mounted) return;
      ref.invalidate(myTeamJoinRequestsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${request.teamName} 가입 신청을 취소했습니다.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage(error, '가입 신청을 취소하지 못했습니다.')),
        ),
      );
    } finally {
      if (mounted) {
        setState(
          () => _cancelingRequestIds.remove(request.teamJoinRequestId),
        );
      }
    }
  }

  Future<void> _leaveTeam(MemberMe member) async {
    final teamId = member.teamId;
    if (teamId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('팀 탈퇴'),
        content: Text('${member.teamName} 팀에서 탈퇴할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('팀 탈퇴'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _leavingTeam = true);
    try {
      final result = await ref.read(memberRepositoryProvider).leaveTeam();
      if (!mounted) return;
      ref.invalidate(memberMeProvider);
      ref.invalidate(memberRankingsProvider);
      ref.invalidate(teamsProvider);
      ref.invalidate(teamDetailProvider(teamId));
      ref.invalidate(teamMembersProvider(teamId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.teamName} 팀에서 탈퇴했습니다.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage(error, '팀에서 탈퇴하지 못했습니다.')),
        ),
      );
    } finally {
      if (mounted) setState(() => _leavingTeam = false);
    }
  }

  Future<void> _openTeam(int teamId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => TeamDetailScreen(teamId: teamId)),
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(memberMeProvider);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: member.when(
        loading: () => const _LoadingView(),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(memberMeProvider),
        ),
        data: (item) {
          final joinRequests = item.hasTeam
              ? null
              : ref.watch(myTeamJoinRequestsProvider);
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              _ProfileCard(
                member: item,
                onOpenTeam: item.teamId == null
                    ? null
                    : () => _openTeam(item.teamId!),
              ),
              if (item.hasTeam && !item.isTeamLeader) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _leavingTeam ? null : () => _leaveTeam(item),
                  icon: _leavingTeam
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.exit_to_app),
                  label: const Text('팀 탈퇴'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
              if (joinRequests != null) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      '내 가입 신청',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    joinRequests.when(
                      data: (items) => Text('${items.length}건'),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                joinRequests.when(
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (error, _) => _InlineError(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(myTeamJoinRequestsProvider),
                  ),
                  data: (items) => items.isEmpty
                      ? const _EmptyRequestsCard()
                      : Column(
                          children: items
                              .map(
                                (request) => Padding(
                                  padding: const EdgeInsets.only(bottom: 9),
                                  child: _JoinRequestCard(
                                    request: request,
                                    canceling: _cancelingRequestIds.contains(
                                      request.teamJoinRequestId,
                                    ),
                                    onOpenTeam: () => _openTeam(request.teamId),
                                    onCancel: () => _cancelRequest(request),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                ),
              ],
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout),
                label: const Text('로그아웃'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
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

    if (confirmed == true && context.mounted) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  String _errorMessage(Object error, String fallback) {
    return error is ApiException ? error.message : fallback;
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.member, required this.onOpenTeam});

  final MemberMe member;
  final VoidCallback? onOpenTeam;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [AppTheme.navy, AppTheme.navySoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -30,
            child: Icon(
              Icons.sports_soccer,
              size: 150,
              color: Colors.white.withValues(alpha: 0.055),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppTheme.lime,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 39,
                        color: AppTheme.navy,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MY FOOTBALL LOG',
                            style: TextStyle(
                              color: AppTheme.lime,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            member.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            '회원 번호 ${member.memberId} · 가입 ${_formatDate(member.createdAt)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.68),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.trending_up,
                        color: AppTheme.lime,
                        size: 27,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'MEMBER RATING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Text(
                        '${member.memberRating}',
                        style: const TextStyle(
                          color: AppTheme.lime,
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const ValueKey('profile-team-link'),
                    onTap: onOpenTeam,
                    borderRadius: BorderRadius.circular(17),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            color: AppTheme.lime,
                            size: 25,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'MY TEAM',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  member.teamName ?? '소속 팀 없음',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (member.hasTeam)
                                  Text(
                                    member.isTeamLeader ? '팀장' : '팀원',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.68,
                                      ),
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (member.hasTeam)
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white70,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinRequestCard extends StatelessWidget {
  const _JoinRequestCard({
    required this.request,
    required this.canceling,
    required this.onOpenTeam,
    required this.onCancel,
  });

  final MyTeamJoinRequest request;
  final bool canceling;
  final VoidCallback onOpenTeam;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.schedule_send_outlined)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.teamName,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text('${_formatDate(request.createdAt)} 신청'),
                    ],
                  ),
                ),
                const _PendingChip(),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onOpenTeam,
                    child: const Text('팀 보기'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: canceling ? null : onCancel,
                    child: canceling
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('신청 취소'),
                  ),
                ),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        '대기',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyRequestsCard extends StatelessWidget {
  const _EmptyRequestsCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Row(
          children: [
            Icon(Icons.inbox_outlined, size: 32),
            SizedBox(width: 14),
            Expanded(child: Text('대기 중인 팀 가입 신청이 없습니다.')),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
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

String _formatDate(DateTime? value) {
  if (value == null) return '-';
  return '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';
}
