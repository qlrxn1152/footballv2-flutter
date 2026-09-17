import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../data/footmatch_repository.dart';

class FootmatchDirectory extends ConsumerStatefulWidget {
  const FootmatchDirectory({super.key, required this.teams, this.onTeamSelected});
  final bool teams;
  final ValueChanged<int>? onTeamSelected;

  @override
  ConsumerState<FootmatchDirectory> createState() => _FootmatchDirectoryState();
}

class _FootmatchDirectoryState extends ConsumerState<FootmatchDirectory> {
  late Future<List<Map<String, dynamic>>> _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = ref.read(footmatchRepositoryProvider);
    _items = widget.teams ? repo.allTeams() : repo.allMembers();
  }

  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: Text(widget.teams ? '팀 목록' : '회원 목록',
            style: Theme.of(context).textTheme.titleLarge)),
        IconButton(tooltip: '목록 새로고침', onPressed: () => setState(_load),
            icon: const Icon(Icons.refresh)),
      ]),
      FutureBuilder<List<Map<String, dynamic>>>(future: _items, builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return Column(children: [
            Text(error is ApiException ? error.message : '목록을 불러오지 못했습니다.'),
            TextButton(onPressed: () => setState(_load), child: const Text('다시 시도')),
          ]);
        }
        if (snapshot.data!.isEmpty) return Text(widget.teams ? '등록된 팀이 없습니다.' : '등록된 회원이 없습니다.');
        return Column(children: [for (final item in snapshot.data!)
          ListTile(contentPadding: EdgeInsets.zero,
            leading: Icon(widget.teams ? Icons.groups_outlined : Icons.person_outline),
            title: Text('${item[widget.teams ? 'teamName' : 'username']}'),
            subtitle: Text(widget.teams
                ? '레이팅 ${item['teamRating']} · ${item['teamMemberCount']}명 · 팀장 ${item['leaderUsername']}'
                : '회원 번호 ${item['memberId']} · 레이팅 ${item['rating']}'),
            trailing: widget.teams ? const Icon(Icons.chevron_right) : null,
            onTap: widget.teams ? () => widget.onTeamSelected?.call((item['teamId'] as num).toInt()) : null,
          ),
        ]);
      }),
    ]),
  ));
}
