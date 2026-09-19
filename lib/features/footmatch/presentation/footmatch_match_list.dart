import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../data/footmatch_match.dart';
import '../data/footmatch_repository.dart';

class FootmatchMatchList extends ConsumerStatefulWidget {
  const FootmatchMatchList({super.key, this.teamId, this.onRequest, this.revision = 0});

  final int? teamId;
  final ValueChanged<FootmatchMatch>? onRequest;
  final int revision;

  @override
  ConsumerState<FootmatchMatchList> createState() => _FootmatchMatchListState();
}

class _FootmatchMatchListState extends ConsumerState<FootmatchMatchList> {
  FootmatchMatchStatus _status = FootmatchMatchStatus.pending;
  late Future<List<FootmatchMatch>> _matches;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant FootmatchMatchList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.teamId != widget.teamId || oldWidget.revision != widget.revision) {
      _load();
    }
  }

  void _load() {
    _matches = ref.read(footmatchRepositoryProvider).matches(_status, teamId: widget.teamId);
  }

  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.teamId == null ? '전체 경기' : '팀 경기',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final status in FootmatchMatchStatus.values)
            ChoiceChip(label: Text(status.label), selected: status == _status,
              onSelected: (_) => setState(() { _status = status; _load(); })),
          IconButton(tooltip: '경기 새로고침', onPressed: () => setState(_load),
              icon: const Icon(Icons.refresh)),
        ]),
        const SizedBox(height: 12),
        FutureBuilder<List<FootmatchMatch>>(
          future: _matches,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Column(children: [
                Text(error is ApiException ? error.message : '경기를 불러오지 못했습니다.'),
                TextButton(onPressed: () => setState(_load), child: const Text('다시 시도')),
              ]);
            }
            final matches = snapshot.data!;
            if (matches.isEmpty) return Text('${_status.label} 경기가 없습니다.');
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final match in matches) Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(match.status == FootmatchMatchStatus.pending
                      ? match.homeName : '${match.homeName} vs ${match.awayName}',
                      style: Theme.of(context).textTheme.titleMedium),
                  SelectableText('경기 번호 ${match.id} · ${match.status.label}'),
                  Text('홈: ${match.homeName} · 레이팅 ${match.homeRating} · 팀장 ${match.homeLeader}'),
                  if (match.awayName != null)
                    Text('원정: ${match.awayName} · 레이팅 ${match.awayRating} · 팀장 ${match.awayLeader}'),
                  Text(match.playedAt == null ? '경기 일시 정보 없음' : '경기 일시 ${_date(match.playedAt!)}'),
                  if (match.createdAt != null) Text('등록 일시 ${_date(match.createdAt!)}'),
                  if (match.status == FootmatchMatchStatus.completed)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        match.isDraw
                            ? '경기 결과 · 무승부'
                            : '경기 결과 · ${match.winnerTeamName} 승리',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  if (match.status == FootmatchMatchStatus.pending && widget.onRequest != null)
                    Align(alignment: Alignment.centerRight, child: TextButton(
                      onPressed: () => widget.onRequest!(match), child: const Text('이 경기 참가 신청'))),
                  const Divider(),
                ]),
              ),
            ]);
          },
        ),
      ]),
    ),
  );
}
