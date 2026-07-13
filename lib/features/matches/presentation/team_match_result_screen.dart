import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/status_banner.dart';
import '../../teams/data/team_models.dart';
import '../../teams/data/team_repository.dart';
import '../data/team_match.dart';
import '../data/team_match_repository.dart';

class TeamMatchResultScreen extends ConsumerStatefulWidget {
  const TeamMatchResultScreen({required this.match, super.key});

  final TeamMatchSummary match;

  @override
  ConsumerState<TeamMatchResultScreen> createState() =>
      _TeamMatchResultScreenState();
}

class _TeamMatchResultScreenState
    extends ConsumerState<TeamMatchResultScreen> {
  final _formKey = GlobalKey<FormState>();
  final _homeScoreController = TextEditingController();
  final _awayScoreController = TextEditingController();
  final Map<({int teamId, int memberId}), int> _goalCounts = {};
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _homeScoreController.dispose();
    _awayScoreController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final homeScore = int.parse(_homeScoreController.text);
    final awayScore = int.parse(_awayScoreController.text);
    final homeGoalTotal = _goalTotal(widget.match.homeTeamId);
    final awayTeamId = widget.match.awayTeamId;
    final awayGoalTotal = awayTeamId == null ? 0 : _goalTotal(awayTeamId);

    if (homeScore != homeGoalTotal) {
      setState(() {
        _errorMessage =
            '${widget.match.homeTeamName}의 점수($homeScore)와 '
            '득점자 합계($homeGoalTotal)가 다릅니다.';
      });
      return;
    }
    if (awayScore != awayGoalTotal) {
      setState(() {
        _errorMessage =
            '${widget.match.awayTeamName ?? '원정 팀'}의 점수($awayScore)와 '
            '득점자 합계($awayGoalTotal)가 다릅니다.';
      });
      return;
    }

    final goals = _goalInputs();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('결과 등록'),
        content: Text(
          '${widget.match.homeTeamName} $homeScore : $awayScore '
          '${widget.match.awayTeamName ?? '상대 팀'}\n\n'
          '득점자 ${goals.length}명의 기록을 포함해 '
          '이 점수로 결과를 등록할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('등록하기'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final result = await ref.read(teamMatchRepositoryProvider).registerResult(
        teamMatchId: widget.match.teamMatchId,
        homeScore: homeScore,
        awayScore: awayScore,
        goals: goals,
      );
      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = error is ApiException
            ? error.message
            : '매치 결과를 등록하지 못했습니다.';
      });
    }
  }

  String? _validateScore(String? value) {
    if (value == null || value.trim().isEmpty) return '점수를 입력해주세요.';
    final score = int.tryParse(value);
    if (score == null || score < 0) return '0 이상의 숫자를 입력해주세요.';
    return null;
  }

  int _scoreOf(TextEditingController controller) {
    return int.tryParse(controller.text) ?? 0;
  }

  int _goalTotal(int teamId) {
    return _goalCounts.entries
        .where((entry) => entry.key.teamId == teamId)
        .fold(0, (sum, entry) => sum + entry.value);
  }

  int _goalCountOf(int teamId, int memberId) {
    return _goalCounts[(teamId: teamId, memberId: memberId)] ?? 0;
  }

  void _changeGoal(TeamMember member, int delta) {
    final key = (teamId: member.teamId, memberId: member.memberId);
    final next = (_goalCounts[key] ?? 0) + delta;
    setState(() {
      if (next <= 0) {
        _goalCounts.remove(key);
      } else {
        _goalCounts[key] = next;
      }
      _errorMessage = null;
    });
  }

  List<TeamMatchGoalInput> _goalInputs() {
    final entries = _goalCounts.entries.where((entry) => entry.value > 0);
    return entries
        .map(
          (entry) => TeamMatchGoalInput(
            teamId: entry.key.teamId,
            scorerMemberId: entry.key.memberId,
            goalCount: entry.value,
          ),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final awayTeamName = widget.match.awayTeamName ?? '상대 팀';
    final awayTeamId = widget.match.awayTeamId;
    final homeMembers = ref.watch(
      teamMembersProvider(widget.match.homeTeamId),
    );
    final awayMembers = awayTeamId == null
        ? null
        : ref.watch(teamMembersProvider(awayTeamId));
    final homeScore = _scoreOf(_homeScoreController);
    final awayScore = _scoreOf(_awayScoreController);

    return Scaffold(
      appBar: AppBar(title: const Text('매치 결과 입력')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox.square(
                  dimension: 19,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sports_score_outlined),
          label: const Text('결과 등록'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            if (_errorMessage != null) ...[
              StatusBanner(message: _errorMessage!),
              const SizedBox(height: 14),
            ],
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Text(
                    'MATCH #${widget.match.teamMatchId}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _ScoreInput(
                          label: 'HOME',
                          teamName: widget.match.homeTeamName,
                          controller: _homeScoreController,
                          validator: _validateScore,
                          onChanged: (_) => setState(() {
                            _errorMessage = null;
                          }),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          ':',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _ScoreInput(
                          label: 'AWAY',
                          teamName: awayTeamName,
                          controller: _awayScoreController,
                          validator: _validateScore,
                          onChanged: (_) => setState(() {
                            _errorMessage = null;
                          }),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '득점자 입력',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '각 선수의 + 버튼을 눌러 팀 점수와 득점 합계를 맞춰주세요.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _GoalTeamCard(
              teamName: widget.match.homeTeamName,
              label: 'HOME',
              expectedScore: homeScore,
              assignedGoals: _goalTotal(widget.match.homeTeamId),
              members: homeMembers,
              goalCountOf: (memberId) =>
                  _goalCountOf(widget.match.homeTeamId, memberId),
              onGoalChanged: _changeGoal,
            ),
            const SizedBox(height: 12),
            if (awayTeamId == null || awayMembers == null)
              const StatusBanner(message: '원정 팀 정보를 불러오지 못했습니다.')
            else
              _GoalTeamCard(
                teamName: awayTeamName,
                label: 'AWAY',
                expectedScore: awayScore,
                assignedGoals: _goalTotal(awayTeamId),
                members: awayMembers,
                goalCountOf: (memberId) =>
                    _goalCountOf(awayTeamId, memberId),
                onGoalChanged: _changeGoal,
              ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '결과 등록은 홈 팀의 팀장만 할 수 있으며, 점수와 득점자 기록은 등록 후 수정할 수 없습니다.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreInput extends StatelessWidget {
  const _ScoreInput({
    required this.label,
    required this.teamName,
    required this.controller,
    required this.validator,
    required this.onChanged,
  });

  final String label;
  final String teamName;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          teamName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          validator: validator,
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.next,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            hintText: '0',
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _GoalTeamCard extends StatelessWidget {
  const _GoalTeamCard({
    required this.teamName,
    required this.label,
    required this.expectedScore,
    required this.assignedGoals,
    required this.members,
    required this.goalCountOf,
    required this.onGoalChanged,
  });

  final String teamName;
  final String label;
  final int expectedScore;
  final int assignedGoals;
  final AsyncValue<List<TeamMember>> members;
  final int Function(int memberId) goalCountOf;
  final void Function(TeamMember member, int delta) onGoalChanged;

  @override
  Widget build(BuildContext context) {
    final matchesScore = expectedScore == assignedGoals;
    final progress = expectedScore == 0
        ? 0.0
        : (assignedGoals / expectedScore).clamp(0.0, 1.0).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    teamName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '$assignedGoals / $expectedScore골',
                  style: TextStyle(
                    color: matchesScore
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 12),
            if (expectedScore == 0 && assignedGoals == 0)
              const Text('0점이면 득점자를 선택하지 않아도 됩니다.')
            else
              members.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, _) => const Text('팀원 목록을 불러오지 못했습니다.'),
                data: (items) {
                  if (items.isEmpty) {
                    return const Text('선택할 수 있는 팀원이 없습니다.');
                  }
                  return Column(
                    children: [
                      for (final member in items)
                        _GoalMemberRow(
                          member: member,
                          goalCount: goalCountOf(member.memberId),
                          onChanged: onGoalChanged,
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

class _GoalMemberRow extends StatelessWidget {
  const _GoalMemberRow({
    required this.member,
    required this.goalCount,
    required this.onChanged,
  });

  final TeamMember member;
  final int goalCount;
  final void Function(TeamMember member, int delta) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            child: Text(member.username.characters.first.toUpperCase()),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.username,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  member.isLeader ? '팀장' : '팀원',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            key: ValueKey('goal-minus-${member.teamId}-${member.memberId}'),
            onPressed: goalCount == 0 ? null : () => onChanged(member, -1),
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: '득점 1 감소',
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$goalCount',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            key: ValueKey('goal-plus-${member.teamId}-${member.memberId}'),
            onPressed: () => onChanged(member, 1),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: '득점 1 추가',
          ),
        ],
      ),
    );
  }
}
