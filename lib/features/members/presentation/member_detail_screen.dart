import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../teams/presentation/team_detail_screen.dart';
import '../data/member_detail.dart';
import '../data/member_repository.dart';

class MemberDetailScreen extends ConsumerWidget {
  const MemberDetailScreen({required this.memberId, super.key});

  final int memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(memberDetailProvider(memberId));

    return Scaffold(
      appBar: AppBar(title: const Text('선수 상세')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(memberDetailProvider(memberId));
          await ref.read(memberDetailProvider(memberId).future);
        },
        child: detail.when(
          loading: () => const _LoadingView(),
          error: (error, _) => _ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(memberDetailProvider(memberId)),
          ),
          data: (member) => _MemberDetailContent(member: member),
        ),
      ),
    );
  }
}

class _MemberDetailContent extends StatelessWidget {
  const _MemberDetailContent({required this.member});

  final MemberDetail member;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _MemberHero(member: member),
        const SizedBox(height: 20),
        Text(
          '선수 정보',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: '회원 번호',
                  value: '${member.memberId}',
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.sports_soccer_outlined,
                  label: '총 득점',
                  value: '${member.totalGoalCount}골',
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: '가입일',
                  value: _formatDate(member.createdAt),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '소속 팀',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        if (member.hasTeam)
          _TeamCard(member: member)
        else
          const _NoTeamCard(),
      ],
    );
  }
}

class _MemberHero extends StatelessWidget {
  const _MemberHero({required this.member});

  final MemberDetail member;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF087F5B), Color(0xFF12B886)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 44),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  member.teamName ?? 'FREE AGENT',
                  style: const TextStyle(color: Color(0xFFD3F9D8)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${member.memberRating}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'RATING',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Text(label),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.member});

  final MemberDetail member;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => TeamDetailScreen(teamId: member.teamId!),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: const Icon(Icons.shield_outlined),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.teamName!,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${member.isLeader ? 'LEADER' : 'MEMBER'} · ${_formatDate(member.joinedAt)} 가입',
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoTeamCard extends StatelessWidget {
  const _NoTeamCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Icon(
              Icons.group_off_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('소속 팀 없음', style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 3),
                  Text('현재 자유 선수 상태입니다.'),
                ],
              ),
            ),
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
        const Icon(Icons.person_off_outlined, size: 54),
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

String _formatDate(DateTime? value) {
  if (value == null) return '-';
  return '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';
}
