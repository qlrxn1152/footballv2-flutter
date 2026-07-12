import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/team_match_history.dart';
import '../data/team_match_repository.dart';
import 'team_match_detail_screen.dart';

enum _HistoryStatus { pending, matched, completed }

extension on _HistoryStatus {
  String get apiValue => switch (this) {
    _HistoryStatus.pending => 'PENDING',
    _HistoryStatus.matched => 'MATCHED',
    _HistoryStatus.completed => 'COMPLETED',
  };
}

class TeamMatchHistorySection extends ConsumerStatefulWidget {
  const TeamMatchHistorySection({required this.teamId, super.key});

  final int teamId;

  @override
  ConsumerState<TeamMatchHistorySection> createState() =>
      _TeamMatchHistorySectionState();
}

class _TeamMatchHistorySectionState
    extends ConsumerState<TeamMatchHistorySection> {
  _HistoryStatus _status = _HistoryStatus.pending;

  TeamMatchHistoryQuery get _query => (
    teamId: widget.teamId,
    status: _status.apiValue,
  );

  void _retry() {
    ref.invalidate(teamMatchHistoryProvider(_query));
  }

  Future<void> _openDetail(int teamMatchId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TeamMatchDetailScreen(teamMatchId: teamMatchId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final matches = ref.watch(teamMatchHistoryProvider(_query));
    final count = matches.when(
      data: (items) => '${items.length}경기',
      loading: () => '조회 중',
      error: (_, _) => '조회 실패',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '매치 기록',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            Text(count),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<_HistoryStatus>(
            segments: const [
              ButtonSegment(
                value: _HistoryStatus.pending,
                icon: Icon(Icons.hourglass_top_outlined),
                label: Text('대기'),
              ),
              ButtonSegment(
                value: _HistoryStatus.matched,
                icon: Icon(Icons.handshake_outlined),
                label: Text('매칭'),
              ),
              ButtonSegment(
                value: _HistoryStatus.completed,
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
        const SizedBox(height: 12),
        matches.when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, _) => _HistoryError(
            message: error is ApiException ? error.message : error.toString(),
            onRetry: _retry,
          ),
          data: (items) => items.isEmpty
              ? _EmptyHistory(status: _status)
              : Column(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      _HistoryMatchCard(
                        match: items[index],
                        onOpenDetail: () =>
                            _openDetail(items[index].teamMatchId),
                      ),
                      if (index != items.length - 1)
                        const SizedBox(height: 9),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _HistoryMatchCard extends StatelessWidget {
  const _HistoryMatchCard({
    required this.match,
    required this.onOpenDetail,
  });

  final TeamMatchHistory match;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final awayName = match.awayTeamName ?? '상대 팀 대기 중';
    final centerLabel = match.isCompleted && match.hasResult
        ? '${match.homeScore} : ${match.awayScore}'
        : match.isPending
        ? 'WAIT'
        : 'VS';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _HistoryTeam(
                    label: 'HOME',
                    name: match.homeTeamName,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    centerLabel,
                    style: TextStyle(
                      fontSize: match.hasResult ? 20 : 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  child: _HistoryTeam(
                    label: 'AWAY',
                    name: awayName,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
            if (match.isCompleted && match.hasResult) ...[
              const SizedBox(height: 13),
              _HistoryResult(match: match),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  '매치 #${match.teamMatchId}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                _HistoryStatusChip(status: match.status),
                const SizedBox(width: 8),
                Text('경기 ${_formatDateTime(match.playedAt)}'),
              ],
            ),
            const SizedBox(height: 11),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenDetail,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('매치 상세'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTeam extends StatelessWidget {
  const _HistoryTeam({
    required this.label,
    required this.name,
    this.alignEnd = false,
  });

  final String label;
  final String name;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _HistoryResult extends StatelessWidget {
  const _HistoryResult({required this.match});

  final TeamMatchHistory match;

  @override
  Widget build(BuildContext context) {
    final isDraw = match.isDraw;
    final winnerName = match.winnerTeamName ??
        ((match.homeScore ?? 0) > (match.awayScore ?? 0)
            ? match.homeTeamName
            : match.awayTeamName ?? '상대 팀');
    final color = isDraw
        ? const Color(0xFF495057)
        : const Color(0xFF5F3DC4);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isDraw ? Icons.balance_outlined : Icons.emoji_events_outlined,
            color: color,
            size: 19,
          ),
          const SizedBox(width: 7),
          Text(
            isDraw ? '무승부' : '$winnerName 승리',
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _HistoryStatusChip extends StatelessWidget {
  const _HistoryStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'PENDING' => const Color(0xFFF08C00),
      'MATCHED' => const Color(0xFF087F5B),
      _ => const Color(0xFF5F3DC4),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.status});

  final _HistoryStatus status;

  @override
  Widget build(BuildContext context) {
    final message = switch (status) {
      _HistoryStatus.pending => '대기 중인 매치가 없습니다.',
      _HistoryStatus.matched => '매칭된 경기가 없습니다.',
      _HistoryStatus.completed => '완료된 경기가 없습니다.',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(message)),
      ),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.message, required this.onRetry});

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
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
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
