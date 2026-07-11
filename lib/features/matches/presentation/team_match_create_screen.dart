import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/status_banner.dart';
import '../data/team_match.dart';
import '../data/team_match_repository.dart';

class TeamMatchCreateScreen extends ConsumerStatefulWidget {
  const TeamMatchCreateScreen({
    required this.teamId,
    required this.teamName,
    required this.teamRating,
    super.key,
  });

  final int teamId;
  final String teamName;
  final int teamRating;

  @override
  ConsumerState<TeamMatchCreateScreen> createState() =>
      _TeamMatchCreateScreenState();
}

class _TeamMatchCreateScreenState
    extends ConsumerState<TeamMatchCreateScreen> {
  bool _submitting = false;
  String? _errorMessage;
  TeamMatchCreateResult? _result;

  Future<void> _createMatch() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('매치 등록'),
        content: Text(
          '${widget.teamName}을 홈 팀으로 매치를 등록할까요?\n\n'
          '등록 후 상대 팀의 참가를 기다리는 PENDING 상태가 됩니다.',
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
      final result = await ref
          .read(teamMatchRepositoryProvider)
          .createMatch(widget.teamId);
      if (!mounted) return;
      ref.invalidate(teamMatchesProvider('PENDING'));
      setState(() {
        _submitting = false;
        _result = result;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = error is ApiException
            ? error.message
            : '매치를 등록하지 못했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: const Text('매치 등록')),
      body: result == null ? _buildRegistration() : _buildSuccess(result),
    );
  }

  Widget _buildRegistration() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            StatusBanner(message: _errorMessage!),
            const SizedBox(height: 14),
          ],
          _HomeTeamCard(
            teamName: widget.teamName,
            teamRating: widget.teamRating,
          ),
          const SizedBox(height: 18),
          const _MatchFlowCard(),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submitting ? null : _createMatch,
            icon: _submitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_circle_outline),
            label: const Text('매치 등록'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(TeamMatchCreateResult result) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                child: const Icon(Icons.check, size: 38),
              ),
              const SizedBox(height: 16),
              Text(
                '매치 등록 완료',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '상대 팀의 참가를 기다리고 있습니다.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _ResultRow(label: '매치 번호', value: '#${result.teamMatchId}'),
                const Divider(height: 26),
                _ResultRow(label: '홈 팀', value: result.homeTeamName),
                const Divider(height: 26),
                _ResultRow(
                  label: '팀 레이팅',
                  value: '${result.homeTeamRating}',
                ),
                const Divider(height: 26),
                _ResultRow(label: '상태', value: _statusLabel(result.status)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(result),
          child: const Text('팀 상세로 돌아가기'),
        ),
      ],
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'PENDING' => '상대 팀 대기 중',
      'MATCHED' => '매칭 완료',
      'COMPLETED' => '경기 완료',
      _ => status,
    };
  }
}

class _HomeTeamCard extends StatelessWidget {
  const _HomeTeamCard({required this.teamName, required this.teamRating});

  final String teamName;
  final int teamRating;

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
          const Row(
            children: [
              Icon(Icons.home_outlined, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'HOME TEAM',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            teamName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'TEAM RATING $teamRating',
            style: const TextStyle(color: Color(0xFFD3F9D8)),
          ),
        ],
      ),
    );
  }
}

class _MatchFlowCard extends StatelessWidget {
  const _MatchFlowCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '등록 전 확인',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 14),
            _FlowItem(
              icon: Icons.hourglass_top_outlined,
              text: '등록 직후 상태는 PENDING입니다.',
            ),
            SizedBox(height: 11),
            _FlowItem(
              icon: Icons.group_add_outlined,
              text: '상대 팀은 이후 참가 기능을 통해 결정됩니다.',
            ),
            SizedBox(height: 11),
            _FlowItem(
              icon: Icons.block_outlined,
              text: '이미 대기 또는 진행 중인 매치가 있으면 등록할 수 없습니다.',
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowItem extends StatelessWidget {
  const _FlowItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21),
        const SizedBox(width: 11),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}
