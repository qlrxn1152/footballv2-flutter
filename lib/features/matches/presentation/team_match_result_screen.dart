import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/status_banner.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('결과 등록'),
        content: Text(
          '${widget.match.homeTeamName} $homeScore : $awayScore '
          '${widget.match.awayTeamName ?? '상대 팀'}\n\n'
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

  @override
  Widget build(BuildContext context) {
    final awayTeamName = widget.match.awayTeamName ?? '상대 팀';

    return Scaffold(
      appBar: AppBar(title: const Text('매치 결과 입력')),
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
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                        '결과 등록은 홈 팀의 팀장만 할 수 있으며, 등록 후에는 수정할 수 없습니다.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox.square(
                      dimension: 19,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sports_score_outlined),
              label: const Text('결과 등록'),
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
  });

  final String label;
  final String teamName;
  final TextEditingController controller;
  final String? Function(String?) validator;

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
