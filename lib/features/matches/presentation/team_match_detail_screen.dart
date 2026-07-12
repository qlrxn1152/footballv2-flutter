import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/team_match.dart';
import '../data/team_match_repository.dart';

class TeamMatchDetailScreen extends ConsumerStatefulWidget {
  const TeamMatchDetailScreen({required this.teamMatchId, super.key});

  final int teamMatchId;

  @override
  ConsumerState<TeamMatchDetailScreen> createState() =>
      _TeamMatchDetailScreenState();
}

class _TeamMatchDetailScreenState
    extends ConsumerState<TeamMatchDetailScreen> {
  Future<void> _refresh() async {
    ref.invalidate(teamMatchDetailProvider(widget.teamMatchId));
    await ref.read(teamMatchDetailProvider(widget.teamMatchId).future);
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(teamMatchDetailProvider(widget.teamMatchId));

    return Scaffold(
      appBar: AppBar(title: const Text('매치 상세')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: detail.when(
          loading: () => const _DetailLoading(),
          error: (error, _) => _DetailError(
            message: error is ApiException ? error.message : error.toString(),
            onRetry: _refresh,
          ),
          data: (match) => _DetailContent(match: match),
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.match});

  final TeamMatchDetail match;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _MatchHero(match: match),
        const SizedBox(height: 14),
        _MatchupCard(match: match),
        if (match.isCompleted && match.hasResult) ...[
          const SizedBox(height: 14),
          _ResultCard(match: match),
        ],
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _InfoRow(
                  label: '경기 일시',
                  value: _formatFullDateTime(match.playedAt),
                ),
                const Divider(height: 26),
                _InfoRow(
                  label: '등록 일시',
                  value: _formatFullDateTime(match.createdAt),
                ),
              ],
            ),
          ),
        ),
        if (match.isPending) ...[
          const SizedBox(height: 14),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.hourglass_top_outlined),
                  SizedBox(width: 12),
                  Expanded(child: Text('현재 상대 팀의 매치 수락을 기다리고 있습니다.')),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MatchHero extends StatelessWidget {
  const _MatchHero({required this.match});

  final TeamMatchDetail match;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (match.status) {
      'PENDING' => ('상대 팀 대기 중', const Color(0xFFF08C00), Icons.hourglass_top),
      'MATCHED' => ('매칭 완료', const Color(0xFF087F5B), Icons.handshake_outlined),
      'COMPLETED' => ('경기 완료', const Color(0xFF5F3DC4), Icons.emoji_events_outlined),
      _ => (match.status, const Color(0xFF495057), Icons.sports_soccer),
    };

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 9),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '#${match.teamMatchId}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            '경기 예정 일시',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            _formatFullDateTime(match.playedAt),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchupCard extends StatelessWidget {
  const _MatchupCard({required this.match});

  final TeamMatchDetail match;

  @override
  Widget build(BuildContext context) {
    final center = match.hasResult
        ? '${match.homeScore} : ${match.awayScore}'
        : match.isPending
        ? 'WAIT'
        : 'VS';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _TeamSide(
                label: 'HOME',
                name: match.homeTeamName,
                rating: match.homeTeamRating.toString(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                center,
                style: TextStyle(
                  fontSize: match.hasResult ? 23 : 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              child: _TeamSide(
                label: 'AWAY',
                name: match.awayTeamName ?? '상대 팀 미정',
                rating: match.awayTeamRating?.toString() ?? '-',
                alignEnd: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamSide extends StatelessWidget {
  const _TeamSide({
    required this.label,
    required this.name,
    required this.rating,
    this.alignEnd = false,
  });

  final String label;
  final String name;
  final String rating;
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
        const SizedBox(height: 4),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        Text('RATING $rating'),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.match});

  final TeamMatchDetail match;

  @override
  Widget build(BuildContext context) {
    final message = match.isDraw
        ? '무승부'
        : '${match.winnerTeamName ?? '승리 팀'} 승리';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF5F3DC4).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            match.isDraw ? Icons.balance_outlined : Icons.emoji_events_outlined,
            color: const Color(0xFF5F3DC4),
          ),
          const SizedBox(width: 9),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF5F3DC4),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _DetailLoading extends StatelessWidget {
  const _DetailLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 180),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.error_outline, size: 54),
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

String _formatFullDateTime(DateTime? value) {
  if (value == null) return '-';
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}.$month.$day $hour:$minute';
}
