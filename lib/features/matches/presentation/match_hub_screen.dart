import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../members/data/member_account.dart';
import '../../members/data/member_repository.dart';
import '../../teams/data/team_repository.dart';
import '../data/team_match.dart';
import '../data/team_match_repository.dart';
import 'team_match_create_screen.dart';
import 'team_match_detail_screen.dart';
import 'team_match_result_screen.dart';

enum _MatchStatusTab { all, pending, matched, completed }

extension on _MatchStatusTab {
  String get apiValue => switch (this) {
    _MatchStatusTab.all => 'ALL',
    _MatchStatusTab.pending => 'PENDING',
    _MatchStatusTab.matched => 'MATCHED',
    _MatchStatusTab.completed => 'COMPLETED',
  };
}

class MatchHubScreen extends ConsumerStatefulWidget {
  const MatchHubScreen({super.key});

  @override
  ConsumerState<MatchHubScreen> createState() => _MatchHubScreenState();
}

class _MatchHubScreenState extends ConsumerState<MatchHubScreen> {
  _MatchStatusTab _status = _MatchStatusTab.all;
  bool _openingRegistration = false;
  final Set<int> _acceptingMatchIds = {};

  Future<void> _refreshStatus(_MatchStatusTab status) async {
    if (status == _MatchStatusTab.all) {
      for (final value in const ['PENDING', 'MATCHED', 'COMPLETED']) {
        ref.invalidate(teamMatchesProvider(value));
      }
      ref.invalidate(allTeamMatchesProvider);
      await ref.read(allTeamMatchesProvider.future);
      return;
    }
    final provider = teamMatchesProvider(status.apiValue);
    ref.invalidate(provider);
    await ref.read(provider.future);
  }

  void _invalidateTeamHistory(
    Iterable<int> teamIds,
    Iterable<String> statuses,
  ) {
    for (final teamId in teamIds.toSet()) {
      for (final status in statuses) {
        ref.invalidate(
          teamMatchHistoryProvider((teamId: teamId, status: status)),
        );
      }
    }
  }

  Future<void> _openRegistration() async {
    setState(() => _openingRegistration = true);
    try {
      final member = await ref.read(memberMeProvider.future);
      final teamId = member.teamId;
      if (teamId == null || !member.isTeamLeader) {
        throw const ApiException('소속 팀의 팀장만 매치를 등록할 수 있습니다.');
      }

      ref.invalidate(teamMatchesProvider('PENDING'));
      ref.invalidate(teamMatchesProvider('MATCHED'));
      final activeLists = await Future.wait([
        ref.read(teamMatchesProvider('PENDING').future),
        ref.read(teamMatchesProvider('MATCHED').future),
      ]);
      TeamMatchSummary? activeMatch;
      for (final match in activeLists.expand((matches) => matches)) {
        if (match.includesTeam(teamId)) {
          activeMatch = match;
          break;
        }
      }
      if (activeMatch != null) {
        throw ApiException(
          activeMatch.isPending
              ? '이미 등록된 매치 요청이 존재합니다.'
              : '이미 진행 중인 매치가 존재합니다.',
          code: 'DUPLICATE_TEAM_MATCH',
          statusCode: 409,
        );
      }

      final team = await ref.read(teamDetailProvider(teamId).future);
      if (!mounted) return;
      final result = await Navigator.of(context).push<TeamMatchCreateResult>(
        MaterialPageRoute(
          builder: (_) => TeamMatchCreateScreen(
            teamId: team.teamId,
            teamName: team.teamName,
            teamRating: team.teamRating,
          ),
        ),
      );
      if (result == null || !mounted) return;

      ref.invalidate(teamMatchesProvider('PENDING'));
      _invalidateTeamHistory([result.homeTeamId], const ['PENDING']);
      setState(() => _status = _MatchStatusTab.pending);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('매치를 등록했습니다. 상대 팀을 기다립니다.')),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : '매치 등록 화면을 열지 못했습니다.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _openingRegistration = false);
    }
  }

  Future<void> _acceptMatch(
    TeamMatchSummary match,
    MemberMe member,
  ) async {
    final awayTeamName = member.teamName ?? '내 팀';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('매치 수락'),
        content: Text(
          '${match.homeTeamName}의 매치를 수락할까요?\n\n'
          '$awayTeamName 팀이 원정 팀으로 참가하며, 수락하면 MATCHED 상태가 됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('수락하기'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _acceptingMatchIds.add(match.teamMatchId));
    try {
      final result = await ref
          .read(teamMatchRepositoryProvider)
          .acceptMatch(match.teamMatchId);
      if (!mounted) return;

      ref.invalidate(teamMatchesProvider('PENDING'));
      ref.invalidate(teamMatchesProvider('MATCHED'));
      _invalidateTeamHistory(
        [result.homeTeamId, result.awayTeamId],
        const ['PENDING', 'MATCHED'],
      );
      setState(() => _status = _MatchStatusTab.matched);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.homeTeamName} vs ${result.awayTeamName} 매칭이 성사됐습니다.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : '매치를 수락하지 못했습니다.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _acceptingMatchIds.remove(match.teamMatchId));
      }
    }
  }

  Future<void> _openResultRegistration(TeamMatchSummary match) async {
    final result = await Navigator.of(context).push<TeamMatchResult>(
      MaterialPageRoute(builder: (_) => TeamMatchResultScreen(match: match)),
    );
    if (result == null || !mounted) return;

    ref.invalidate(teamMatchesProvider('MATCHED'));
    ref.invalidate(teamMatchesProvider('COMPLETED'));
    ref.invalidate(teamsProvider);
    for (final teamId in {result.homeTeamId, result.awayTeamId}) {
      ref.invalidate(teamDetailProvider(teamId));
    }
    _invalidateTeamHistory(
      [result.homeTeamId, result.awayTeamId],
      const ['MATCHED', 'COMPLETED'],
    );
    setState(() => _status = _MatchStatusTab.completed);

    final outcome = result.isDraw
        ? '무승부'
        : '${result.winnerTeamName} 승리';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${result.homeTeamName} ${result.homeScore} : ${result.awayScore} '
          '${result.awayTeamName} · $outcome',
        ),
      ),
    );
  }

  Future<void> _openMatchDetail(int teamMatchId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TeamMatchDetailScreen(teamMatchId: teamMatchId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(memberMeProvider);
    final pendingMatches = ref.watch(teamMatchesProvider('PENDING'));
    final matchedMatches = ref.watch(teamMatchesProvider('MATCHED'));
    final completedMatches = ref.watch(teamMatchesProvider('COMPLETED'));
    final allMatches = ref.watch(allTeamMatchesProvider);

    final memberValue = member.when(
      data: (item) => item,
      loading: () => null,
      error: (_, _) => null,
    );
    final teamId = memberValue?.teamId;
    final hasPendingMatch = _containsTeam(pendingMatches, teamId);
    final hasMatchedMatch = _containsTeam(matchedMatches, teamId);
    final hasActiveMatch = hasPendingMatch || hasMatchedMatch;
    final activeMatchesResolved =
        _hasData(pendingMatches) && _hasData(matchedMatches);

    final selectedMatches = switch (_status) {
      _MatchStatusTab.all => allMatches,
      _MatchStatusTab.pending => pendingMatches,
      _MatchStatusTab.matched => matchedMatches,
      _MatchStatusTab.completed => completedMatches,
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: _MatchHeader(
            member: member,
            hasPendingMatch: hasPendingMatch,
            hasMatchedMatch: hasMatchedMatch,
            activeMatchesResolved: activeMatchesResolved,
            openingRegistration: _openingRegistration,
            onRegister: _openRegistration,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: SegmentedButton<_MatchStatusTab>(
            segments: const [
              ButtonSegment(
                value: _MatchStatusTab.all,
                icon: Icon(Icons.format_list_bulleted),
                label: Text('전체'),
              ),
              ButtonSegment(
                value: _MatchStatusTab.pending,
                icon: Icon(Icons.hourglass_top_outlined),
                label: Text('대기'),
              ),
              ButtonSegment(
                value: _MatchStatusTab.matched,
                icon: Icon(Icons.handshake_outlined),
                label: Text('매칭'),
              ),
              ButtonSegment(
                value: _MatchStatusTab.completed,
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
        Expanded(
          child: _MatchesView(
            status: _status,
            matches: selectedMatches,
            member: memberValue,
            memberTeamHasActiveMatch: hasActiveMatch,
            memberTeamActivityResolved: activeMatchesResolved,
            acceptingMatchIds: _acceptingMatchIds,
            onRefresh: () => _refreshStatus(_status),
            onAccept: _acceptMatch,
            onEnterResult: _openResultRegistration,
            onOpenDetail: _openMatchDetail,
          ),
        ),
      ],
    );
  }

  bool _containsTeam(
    AsyncValue<List<TeamMatchSummary>> matches,
    int? teamId,
  ) {
    if (teamId == null) return false;
    return matches.when(
      data: (items) => items.any((match) => match.includesTeam(teamId)),
      loading: () => false,
      error: (_, _) => false,
    );
  }

  bool _hasData(AsyncValue<List<TeamMatchSummary>> matches) {
    return matches.when(
      data: (_) => true,
      loading: () => false,
      error: (_, _) => false,
    );
  }
}

class _MatchHeader extends StatelessWidget {
  const _MatchHeader({
    required this.member,
    required this.hasPendingMatch,
    required this.hasMatchedMatch,
    required this.activeMatchesResolved,
    required this.openingRegistration,
    required this.onRegister,
  });

  final AsyncValue<MemberMe> member;
  final bool hasPendingMatch;
  final bool hasMatchedMatch;
  final bool activeMatchesResolved;
  final bool openingRegistration;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final (buttonLabel, canRegister) = member.when(
      data: (item) {
        if (!item.hasTeam) return ('팀 가입 후 등록 가능', false);
        if (!item.isTeamLeader) return ('팀장만 등록 가능', false);
        if (!activeMatchesResolved) return ('매치 확인 중', false);
        if (hasPendingMatch) return ('등록한 매치 대기 중', false);
        if (hasMatchedMatch) return ('진행 중인 매치 있음', false);
        return ('새 매치 등록', true);
      },
      loading: () => ('내 팀 확인 중', false),
      error: (_, _) => ('내 팀 확인 실패', false),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF087F5B), Color(0xFF0CA678)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.sports_soccer, color: Colors.white, size: 30),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TEAM MATCH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '매치를 확인하고 새로운 상대를 만나보세요.',
                      style: TextStyle(color: Color(0xFFD3F9D8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: canRegister && !openingRegistration ? onRegister : null,
            icon: openingRegistration
                ? const SizedBox.square(
                    dimension: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_circle_outline),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _MatchesView extends StatelessWidget {
  const _MatchesView({
    required this.status,
    required this.matches,
    required this.member,
    required this.memberTeamHasActiveMatch,
    required this.memberTeamActivityResolved,
    required this.acceptingMatchIds,
    required this.onRefresh,
    required this.onAccept,
    required this.onEnterResult,
    required this.onOpenDetail,
  });

  final _MatchStatusTab status;
  final AsyncValue<List<TeamMatchSummary>> matches;
  final MemberMe? member;
  final bool memberTeamHasActiveMatch;
  final bool memberTeamActivityResolved;
  final Set<int> acceptingMatchIds;
  final Future<void> Function() onRefresh;
  final Future<void> Function(TeamMatchSummary, MemberMe) onAccept;
  final Future<void> Function(TeamMatchSummary) onEnterResult;
  final Future<void> Function(int) onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: matches.when(
        loading: () => const _LoadingList(),
        error: (error, _) => _MatchErrorView(
          message: error is ApiException ? error.message : error.toString(),
          onRetry: onRefresh,
        ),
        data: (items) => items.isEmpty
            ? _EmptyMatchesView(status: status)
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final match = items[index];
                  if (match.isPending) {
                    return _PendingMatchCard(
                      match: match,
                      member: member,
                      memberTeamHasActiveMatch: memberTeamHasActiveMatch,
                      memberTeamActivityResolved: memberTeamActivityResolved,
                      accepting: acceptingMatchIds.contains(match.teamMatchId),
                      onAccept: onAccept,
                      onOpenDetail: () => onOpenDetail(match.teamMatchId),
                    );
                  }
                  final canEnterResult =
                      match.isMatched &&
                      member?.isTeamLeader == true &&
                      member?.teamId == match.homeTeamId;
                  return _PairedMatchCard(
                    match: match,
                    onEnterResult: canEnterResult
                        ? () => onEnterResult(match)
                        : null,
                    onOpenDetail: () => onOpenDetail(match.teamMatchId),
                  );
                },
              ),
      ),
    );
  }
}

class _PendingMatchCard extends StatelessWidget {
  const _PendingMatchCard({
    required this.match,
    required this.member,
    required this.memberTeamHasActiveMatch,
    required this.memberTeamActivityResolved,
    required this.accepting,
    required this.onAccept,
    required this.onOpenDetail,
  });

  final TeamMatchSummary match;
  final MemberMe? member;
  final bool memberTeamHasActiveMatch;
  final bool memberTeamActivityResolved;
  final bool accepting;
  final Future<void> Function(TeamMatchSummary, MemberMe) onAccept;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  child: const Icon(Icons.shield_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.homeTeamName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text('TEAM RATING ${match.homeTeamRating}'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildAction(),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  '매치 #${match.teamMatchId}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text('경기 ${_formatDateTime(match.playedAt)}'),
              ],
            ),
            const SizedBox(height: 12),
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

  Widget _buildAction() {
    final currentMember = member;
    if (currentMember == null || !currentMember.hasTeam) {
      return const _StatusChip(label: 'PENDING', color: Color(0xFFF08C00));
    }
    if (currentMember.teamId == match.homeTeamId) {
      return const _StatusChip(label: '내 팀 매치', color: Color(0xFF087F5B));
    }
    if (!currentMember.isTeamLeader) {
      return const _StatusChip(label: '팀장만 가능', color: Color(0xFF868E96));
    }

    return FilledButton(
      onPressed: !memberTeamActivityResolved ||
              memberTeamHasActiveMatch ||
              accepting
          ? null
          : () => onAccept(match, currentMember),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        visualDensity: VisualDensity.compact,
      ),
      child: accepting
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              !memberTeamActivityResolved
                  ? '확인 중'
                  : memberTeamHasActiveMatch
                  ? '진행 중'
                  : '매치 수락',
            ),
    );
  }
}

class _PairedMatchCard extends StatelessWidget {
  const _PairedMatchCard({
    required this.match,
    required this.onOpenDetail,
    this.onEnterResult,
  });

  final TeamMatchSummary match;
  final VoidCallback? onEnterResult;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final awayTeamName = match.awayTeamName ?? '상대 팀 미정';
    final awayTeamRating = match.awayTeamRating?.toString() ?? '-';
    final statusColor = match.isCompleted
        ? const Color(0xFF5F3DC4)
        : const Color(0xFF087F5B);
    final versusLabel = match.isCompleted && match.hasResult
        ? '${match.homeScore} : ${match.awayScore}'
        : 'VS';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _TeamSide(
                    name: match.homeTeamName,
                    rating: match.homeTeamRating.toString(),
                    label: 'HOME',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    versusLabel,
                    style: TextStyle(
                      fontSize: match.hasResult ? 21 : 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  child: _TeamSide(
                    name: awayTeamName,
                    rating: awayTeamRating,
                    label: 'AWAY',
                    alignEnd: true,
                  ),
                ),
              ],
            ),
            if (match.isCompleted && match.hasResult) ...[
              const SizedBox(height: 14),
              _MatchResultBanner(match: match),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '매치 #${match.teamMatchId}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                _StatusChip(label: match.status, color: statusColor),
                const SizedBox(width: 8),
                Text('경기 ${_formatDateTime(match.playedAt)}'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenDetail,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('매치 상세'),
              ),
            ),
            if (onEnterResult != null) ...[
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onEnterResult,
                  icon: const Icon(Icons.sports_score_outlined),
                  label: const Text('결과 입력'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MatchResultBanner extends StatelessWidget {
  const _MatchResultBanner({required this.match});

  final TeamMatchSummary match;

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isDraw ? '무승부' : '$winnerName 승리',
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _TeamSide extends StatelessWidget {
  const _TeamSide({
    required this.name,
    required this.rating,
    required this.label,
    this.alignEnd = false,
  });

  final String name;
  final String rating;
  final String label;
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
        Text('RATING $rating'),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _EmptyMatchesView extends StatelessWidget {
  const _EmptyMatchesView({required this.status});

  final _MatchStatusTab status;

  @override
  Widget build(BuildContext context) {
    final message = switch (status) {
      _MatchStatusTab.all => '등록된 매치가 없습니다.',
      _MatchStatusTab.pending => '대기 중인 매치가 없습니다.',
      _MatchStatusTab.matched => '매칭된 경기가 없습니다.',
      _MatchStatusTab.completed => '완료된 경기가 없습니다.',
    };
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 70),
        const Icon(Icons.sports_soccer, size: 56),
        const SizedBox(height: 15),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _MatchErrorView extends StatelessWidget {
  const _MatchErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 70),
        const Icon(Icons.cloud_off_outlined, size: 54),
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

String _formatDateTime(DateTime? value) {
  if (value == null) return '-';
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$month.$day $hour:$minute';
}
