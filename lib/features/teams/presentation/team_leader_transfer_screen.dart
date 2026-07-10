import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../members/data/member_repository.dart';
import '../data/team_models.dart';
import '../data/team_repository.dart';

class TeamLeaderTransferScreen extends ConsumerStatefulWidget {
  const TeamLeaderTransferScreen({
    required this.teamId,
    required this.teamName,
    super.key,
  });

  final int teamId;
  final String teamName;

  @override
  ConsumerState<TeamLeaderTransferScreen> createState() =>
      _TeamLeaderTransferScreenState();
}

class _TeamLeaderTransferScreenState
    extends ConsumerState<TeamLeaderTransferScreen> {
  int? _selectedMemberId;
  bool _transferring = false;

  Future<void> _refresh() async {
    ref.invalidate(teamMembersProvider(widget.teamId));
    await ref.read(teamMembersProvider(widget.teamId).future);
  }

  Future<void> _transfer(TeamMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('팀장 위임'),
        content: Text(
          '${member.username}님에게 ${widget.teamName} 팀장 권한을 위임할까요?\n\n'
          '위임 후 회원님은 일반 팀원이 됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('위임하기'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _transferring = true);
    try {
      final result = await ref.read(teamRepositoryProvider).transferLeader(
        teamId: widget.teamId,
        newLeaderMemberId: member.memberId,
      );
      if (!mounted) return;

      ref.invalidate(teamDetailProvider(widget.teamId));
      ref.invalidate(teamMembersProvider(widget.teamId));
      ref.invalidate(teamsProvider);
      ref.invalidate(memberMeProvider);
      ref.invalidate(memberRankingsProvider);
      ref.invalidate(memberDetailProvider(result.oldLeaderMemberId));
      ref.invalidate(memberDetailProvider(result.newLeaderMemberId));

      Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : '팀장 권한을 위임하지 못했습니다.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      setState(() => _transferring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(teamMembersProvider(widget.teamId));

    return Scaffold(
      appBar: AppBar(title: const Text('팀장 위임')),
      body: members.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(32),
            children: [
              const SizedBox(height: 100),
              const Icon(Icons.error_outline, size: 52),
              const SizedBox(height: 14),
              Text(error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Center(
                child: FilledButton.tonal(
                  onPressed: () => ref.invalidate(
                    teamMembersProvider(widget.teamId),
                  ),
                  child: const Text('다시 시도'),
                ),
              ),
            ],
          ),
        ),
        data: (items) {
          final candidates = items
              .where((member) => !member.isLeader)
              .toList(growable: false);

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      const _TransferWarning(),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Text(
                            '새 팀장 선택',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const Spacer(),
                          Text('${candidates.length}명'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (candidates.isEmpty)
                        const _EmptyCandidates()
                      else
                        ...candidates.map(
                          (member) => Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: _CandidateCard(
                              member: member,
                              selected:
                                  _selectedMemberId == member.memberId,
                              onTap: _transferring
                                  ? null
                                  : () => setState(
                                      () => _selectedMemberId =
                                          member.memberId,
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _transferring || _selectedMemberId == null
                          ? null
                          : () => _transfer(
                              candidates.firstWhere(
                                (member) =>
                                    member.memberId == _selectedMemberId,
                              ),
                            ),
                      icon: _transferring
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.manage_accounts_outlined),
                      label: const Text('선택한 팀원에게 위임'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TransferWarning extends StatelessWidget {
  const _TransferWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3BF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD43B)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 30),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '위임 후에는 일반 팀원이 됩니다',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 5),
                Text('새 팀장만 가입 신청 관리와 다음 팀장 위임을 할 수 있습니다.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.member,
    required this.selected,
    required this.onTap,
  });

  final TeamMember member;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: selected ? colors.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: selected
                    ? colors.primary
                    : colors.surfaceContainerHighest,
                foregroundColor: selected ? colors.onPrimary : null,
                child: const Icon(Icons.person_outline),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.username,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '회원 번호 ${member.memberId} · '
                      '레이팅 ${member.memberRating}',
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: selected ? colors.primary : colors.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCandidates extends StatelessWidget {
  const _EmptyCandidates();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 22, vertical: 30),
        child: Column(
          children: [
            Icon(Icons.person_search_outlined, size: 48),
            SizedBox(height: 12),
            Text(
              '위임 가능한 팀원이 없습니다.',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 5),
            Text('새 팀원이 가입한 뒤 다시 시도하세요.'),
          ],
        ),
      ),
    );
  }
}
