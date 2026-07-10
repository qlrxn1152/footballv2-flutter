import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/status_banner.dart';
import '../../members/data/member_repository.dart';
import '../data/team_repository.dart';

class TeamSettingsOutcome {
  const TeamSettingsOutcome.renamed(this.teamName) : disbanded = false;

  const TeamSettingsOutcome.disbanded(this.teamName) : disbanded = true;

  final String teamName;
  final bool disbanded;
}

class TeamSettingsScreen extends ConsumerStatefulWidget {
  const TeamSettingsScreen({
    required this.teamId,
    required this.teamName,
    required this.memberCount,
    super.key,
  });

  final int teamId;
  final String teamName;
  final int memberCount;

  @override
  ConsumerState<TeamSettingsScreen> createState() =>
      _TeamSettingsScreenState();
}

class _TeamSettingsScreenState extends ConsumerState<TeamSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _updatingName = false;
  bool _disbanding = false;
  String? _errorMessage;

  bool get _canDisband => widget.memberCount == 1;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.teamName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateName() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final newName = _nameController.text.trim();
    if (newName == widget.teamName) {
      setState(() => _errorMessage = '현재 팀 이름과 다른 이름을 입력하세요.');
      return;
    }

    setState(() {
      _updatingName = true;
      _errorMessage = null;
    });
    try {
      final result = await ref.read(teamRepositoryProvider).updateTeamName(
        teamId: widget.teamId,
        teamName: newName,
      );
      if (!mounted) return;

      _invalidateTeamData(result.leaderMemberId);
      Navigator.of(context).pop(TeamSettingsOutcome.renamed(result.teamName));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _updatingName = false;
        _errorMessage = _message(error, '팀 이름을 변경하지 못했습니다.');
      });
    }
  }

  Future<void> _disbandTeam() async {
    if (!_canDisband) return;

    final confirmController = TextEditingController();
    final enteredName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('팀 해체'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.teamName} 팀과 모든 가입 신청 이력이 삭제됩니다. '
              '이 작업은 되돌릴 수 없습니다.',
            ),
            const SizedBox(height: 18),
            TextField(
              controller: confirmController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '확인을 위해 ${widget.teamName} 입력',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(
              context,
              confirmController.text.trim(),
            ),
            child: const Text('팀 해체'),
          ),
        ],
      ),
    );
    confirmController.dispose();
    if (enteredName == null || !mounted) return;
    if (enteredName != widget.teamName) {
      setState(() => _errorMessage = '팀 이름이 일치하지 않습니다.');
      return;
    }

    setState(() {
      _disbanding = true;
      _errorMessage = null;
    });
    try {
      final result = await ref
          .read(teamRepositoryProvider)
          .disbandTeam(widget.teamId);
      if (!mounted) return;

      _invalidateTeamData(result.leaderMemberId);
      Navigator.of(
        context,
      ).pop(TeamSettingsOutcome.disbanded(result.teamName));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _disbanding = false;
        _errorMessage = _message(error, '팀을 해체하지 못했습니다.');
      });
    }
  }

  void _invalidateTeamData(int leaderMemberId) {
    ref.invalidate(teamDetailProvider(widget.teamId));
    ref.invalidate(teamMembersProvider(widget.teamId));
    ref.invalidate(teamsProvider);
    ref.invalidate(memberMeProvider);
    ref.invalidate(memberRankingsProvider);
    ref.invalidate(myTeamJoinRequestsProvider);
    ref.invalidate(memberDetailProvider(leaderMemberId));

    for (final status in const [
      'PENDING',
      'ACCEPTED',
      'REJECTED',
      'CANCELED',
    ]) {
      ref.invalidate(
        joinRequestsProvider((teamId: widget.teamId, status: status)),
      );
    }
  }

  String _message(Object error, String fallback) {
    return error is ApiException ? error.message : fallback;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('팀 설정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              StatusBanner(message: _errorMessage!),
              const SizedBox(height: 14),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 10),
                          Text(
                            '팀 이름 변경',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _nameController,
                        maxLength: 20,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: '새 팀 이름',
                          helperText: '4~20자, 다른 팀과 중복할 수 없습니다.',
                          prefixIcon: Icon(Icons.shield_outlined),
                        ),
                        validator: (value) {
                          final length = value?.trim().length ?? 0;
                          if (length < 4 || length > 20) {
                            return '팀 이름은 4~20자로 입력하세요.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _updateName(),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _updatingName || _disbanding
                            ? null
                            : _updateName,
                        icon: _updatingName
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('팀 이름 변경'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '위험 구역',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.error,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              color: colors.errorContainer.withValues(alpha: 0.35),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.delete_forever_outlined, color: colors.error),
                        const SizedBox(width: 10),
                        Text(
                          '팀 해체',
                          style: TextStyle(
                            color: colors.error,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _canDisband
                          ? '현재 팀장만 남아 있어 팀을 해체할 수 있습니다.'
                          : '현재 ${widget.memberCount}명이 소속되어 있습니다. '
                                '팀장을 제외한 모든 팀원이 탈퇴해야 해체할 수 있습니다.',
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: !_canDisband || _updatingName || _disbanding
                          ? null
                          : _disbandTeam,
                      icon: _disbanding
                          ? const SizedBox.square(
                              dimension: 19,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_forever_outlined),
                      label: Text(
                        _canDisband ? '팀 해체' : '팀원이 있어 해체할 수 없음',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.error,
                        side: BorderSide(color: colors.error),
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
