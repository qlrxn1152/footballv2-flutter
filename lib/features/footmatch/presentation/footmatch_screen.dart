import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/footmatch_repository.dart';
import 'footmatch_match_list.dart';
import 'footmatch_directory.dart';

class FootmatchScreen extends ConsumerStatefulWidget {
  const FootmatchScreen({super.key});
  @override
  ConsumerState<FootmatchScreen> createState() => _FootmatchScreenState();
}

class _FootmatchScreenState extends ConsumerState<FootmatchScreen> {
  final _teamNumber = TextEditingController();
  final _teamName = TextEditingController();
  final _matchNumber = TextEditingController();
  final _matchRequestNumber = TextEditingController();
  int _matchRevision = 0;
  final _requestNumber = TextEditingController();
  final _memberNumber = TextEditingController();
  Map<String, dynamic>? _me;
  Map<String, dynamic>? _team;
  Map<String, dynamic>? _myTeam;
  bool _myTeamLoading = true;
  String? _myTeamError;
  int _memberView = 0;
  int _teamView = 0;
  int _matchScope = 0;
  int _directoryRevision = 0;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>>? _requests;
  final List<String> _receipts = [];
  bool _busy = false;
  String? _error;
  DateTime? _playedAt;
  int _tab = 0;

  FootmatchRepository get _repo => ref.read(footmatchRepositoryProvider);
  int? get _teamId => (_team?['teamId'] as num?)?.toInt();
  int? get _myTeamId => (_myTeam?['teamId'] as num?)?.toInt();
  bool get _myTeamLeader => _myTeam != null &&
      _myTeam!['leaderId'] == ref.read(authControllerProvider).session?.memberId;
  bool get _leader => _team != null &&
      _team!['leaderId'] == ref.read(authControllerProvider).session?.memberId;
  bool get _joined => _leader || _members.any((m) =>
      m['username'] == ref.read(authControllerProvider).session?.username);

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => _run(() async {
      await _loadMe();
      await _loadMyTeam();
    }));
  }

  @override
  void dispose() {
    for (final c in [_teamNumber, _teamName, _matchNumber,
      _requestNumber, _memberNumber, _matchRequestNumber]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (!mounted || _busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      if (error is ApiException && error.statusCode == 401) {
        await ref.read(authControllerProvider.notifier).logout();
        return;
      }
      setState(() => _error = error is ApiException
          ? error.message : '처리하지 못했습니다. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadMe() async {
    final me = await _repo.me();
    if (mounted) setState(() => _me = me);
  }

  Future<void> _loadMyTeam() async {
    if (!mounted) return;
    setState(() { _myTeamLoading = true; _myTeamError = null; });
    try {
      final team = await _repo.myTeam();
      if (mounted) setState(() => _myTeam = team);
    } catch (error) {
      if (mounted) {
        setState(() {
          _myTeam = null;
          _myTeamError = error is ApiException ? error.message : '내 팀을 불러오지 못했습니다.';
        });
      }
    } finally {
      if (mounted) setState(() => _myTeamLoading = false);
    }
  }

  Future<void> _refreshTeam(int id) async {
    await _loadTeam(id);
    await _loadMyTeam();
    if (mounted) setState(() => _directoryRevision++);
  }

  Future<void> _openMyTeam() async {
    await _loadMyTeam();
    if (_myTeamId != null) {
      await _loadTeam(_myTeamId!);
    } else if (mounted) {
      setState(() { _team = null; _members = []; _requests = null; });
    }
  }

  Widget _choices(List<String> labels, int selected, ValueChanged<int> onSelected) =>
      Padding(padding: const EdgeInsets.only(bottom: 12), child: Wrap(spacing: 8, runSpacing: 8,
        children: [for (var i = 0; i < labels.length; i++)
          ChoiceChip(label: Text(labels[i]), selected: selected == i,
              onSelected: _busy ? null : (_) => onSelected(i)),
        ],
      ));

  Widget _myTeamStatus() {
    if (_myTeamLoading) return const Center(child: CircularProgressIndicator());
    return _card('내 소속 팀', [
      Text(_myTeamError ?? (_myTeam == null ? '소속된 팀이 없습니다. 전체 팀에서 가입하거나 팀을 만들어보세요.' : '${_myTeam!['teamName']}')),
      _button('내 팀 새로고침', _openMyTeam),
    ]);
  }

  Widget _memberTab() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _choices(['전체 회원', '내 정보'], _memberView, (value) {
      setState(() => _memberView = value);
      if (value == 1) _run(_loadMe);
    }),
    if (_memberView == 0) const FootmatchDirectory(key: ValueKey('members'), teams: false)
    else _profile(),
  ]);

  Widget _teamTab() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _choices(['전체 팀', '내 팀'], _teamView, (value) {
      setState(() => _teamView = value);
      if (value == 1) _run(_openMyTeam);
    }),
    if (_teamView == 0) ...[
      FootmatchDirectory(key: ValueKey('teams-$_directoryRevision'), teams: true,
          onTeamSelected: (id) => _run(() => _loadTeam(id))),
      _teams(),
    ] else ...[
      _myTeamStatus(),
      if (_myTeam != null && _teamId == _myTeamId) _teams(),
    ],
  ]);

  List<Map<String, dynamic>> _items(dynamic value) =>
      (value as List? ?? []).map((e) => jsonMap(e)).toList();

  Future<void> _loadTeam(int id) async {
    final team = await _repo.team(id);
    final members = await _repo.members(id);
    if (!mounted) return;
    setState(() {
      _team = team;
      _members = _items(members['teamMembers']);
      _requests = null;
      _teamNumber.text = '$id';
    });
  }

  void _receipt(String text) {
    if (!mounted) return;
    setState(() => _receipts.insert(0, text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  int _number(TextEditingController controller, String label) {
    final id = int.tryParse(controller.text.trim());
    if (id == null || id <= 0) throw ApiException('$label를 올바르게 입력해주세요.');
    return id;
  }

  String _name() {
    final value = _teamName.text.trim();
    if (value.length < 2 || value.length > 20) {
      throw const ApiException('팀 이름은 2~20자로 입력해주세요.');
    }
    return value;
  }

  Future<bool> _confirm(String text) async => await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('확인'), content: Text(text),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('진행')),
      ],
    ),
  ) ?? false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(context: context,
        initialDate: now.add(const Duration(days: 1)),
        firstDate: DateTime(now.year, now.month, now.day),
        lastDate: now.add(const Duration(days: 730)));
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context,
        initialTime: const TimeOfDay(hour: 19, minute: 0));
    if (time == null || !mounted) return;
    setState(() => _playedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Widget _field(TextEditingController controller, String label, {bool number = false}) =>
      Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        inputFormatters: number ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(labelText: label),
      ));

  Widget _button(String title, Future<void> Function() action) =>
      FilledButton.tonal(onPressed: _busy ? null : () => _run(action), child: Text(title));

  Widget _card(String title, List<Widget> children) => Card(
    child: Padding(padding: const EdgeInsets.all(20), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16), ...children],
    )),
  );

  Widget _profile() => Column(children: [
    _card('내 정보', [
      if (_me == null) const Text('내 정보를 불러와주세요.') else ...[
        Text('${_me!['username']}', style: Theme.of(context).textTheme.headlineSmall),
        SelectableText('회원 번호 ${_me!['memberId']}'),
        Text('레이팅 ${_me!['rating']}'),
        const SizedBox(height: 8),
        const Text('팀장 위임이나 팀원 관리가 필요할 때 회원 번호를 알려주세요.'),
      ],
      const SizedBox(height: 12), _button('내 정보 새로고침', _loadMe),
    ]),
    _card('시작하기', const [
      Text('팀 탭에서 팀을 만들거나 전달받은 팀 번호로 찾아보세요.\n'
          '경기 탭에서는 경기를 등록하고 경기 번호로 참가 신청할 수 있어요.'),
    ]),
    _card('이번 접속의 처리 내역', [
      const Text('번호가 필요한 내역은 복사해 보관하세요. 새로고침하거나 로그아웃하면 이 목록은 사라집니다.'),
      const SizedBox(height: 12),
      if (_receipts.isEmpty) const Text('아직 처리 내역이 없습니다.'),
      for (final receipt in _receipts) Padding(
        padding: const EdgeInsets.only(bottom: 12), child: SelectableText(receipt)),
    ]),
  ]);

  Widget _teams() => Column(children: [
    if (_teamView == 0) _card('팀 찾기', [
      const Text('전달받은 팀 번호를 입력하세요.'), const SizedBox(height: 12),
      _field(_teamNumber, '팀 번호', number: true),
      _button('팀 조회', () async {
        final id = _number(_teamNumber, '팀 번호');
        setState(() { _team = null; _members = []; _requests = null; });
        await _loadTeam(id);
      }),
    ]),
    if (_teamView == 0 && _myTeam == null) _card('팀 만들기', [
      _field(_teamName, '팀 이름 (2~20자)'),
      _button('팀 생성', () async {
        final result = await _repo.createTeam(_name());
        final id = (result['teamId'] as num).toInt();
        _receipt('팀 생성 완료 · ${result['teamName']} · 팀 번호 $id');
        await _refreshTeam(id);
      }),
    ]),
    if (_team != null) ...[
      _card('${_team!['teamName']}', [
        SelectableText('팀 번호 $_teamId'),
        Text('팀장 ${_team!['leaderUsername']} · 레이팅 ${_team!['teamRating']} · ${_team!['teamMemberCount']}명'),
        const SizedBox(height: 12),
        for (final m in _members) ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.person_outline), title: Text('${m['username']}'),
          subtitle: Text('레이팅 ${m['memberRating']}'),
        ),
        _button('팀 정보 새로고침', () => _refreshTeam(_teamId!)),
        if (!_joined) _button('가입 신청', () async {
          final result = await _repo.join(_teamId!);
          if (!mounted) return;
          _requestNumber.text = '${result['joinRequestId']}';
          _receipt('가입 신청 완료 · 팀 번호 $_teamId · 신청 번호 ${result['joinRequestId']} · 팀장에게 신청 번호를 알려주세요.');
        }),
        if (_joined && !_leader) _button('팀 탈퇴', () async {
          if (!await _confirm('${_team!['teamName']} 팀에서 탈퇴할까요?')) return;
          await _repo.leave(_teamId!);
          _receipt('팀 탈퇴 완료');
          await _refreshTeam(_teamId!);
        }),
      ]),
      FootmatchMatchList(key: ValueKey('team-$_teamId'), teamId: _teamId, revision: _matchRevision),
      _card(_leader ? '가입 신청 관리' : '내 가입 신청 취소', [
        if (_leader) ...[
          _button('대기 신청 조회', () async {
            final data = await _repo.requests(_teamId!);
            if (mounted) setState(() => _requests = _items(data['requests']));
          }),
          if (_requests != null && _requests!.isEmpty) const Text('대기 중인 신청이 없습니다.'),
          for (final r in _requests ?? <Map<String, dynamic>>[]) ListTile(
            title: Text('${r['username']}'),
            subtitle: Text('레이팅 ${r['userRating']} · ${r['createdAt']}'),
          ),
          const Text('신청자에게 전달받은 신청 번호로 수락하거나 거절하세요.'),
        ] else const Text('가입 신청 때 받은 신청 번호를 입력하세요.'),
        const SizedBox(height: 12), _field(_requestNumber, '가입 신청 번호', number: true),
        if (_leader) Wrap(spacing: 8, runSpacing: 8, children: [
          _button('수락', () async {
            final id = _number(_requestNumber, '신청 번호');
            if (!await _confirm('신청 번호 $id 가입을 수락할까요?')) return;
            final r = await _repo.acceptJoin(_teamId!, id);
            _receipt('${r['memberUsername']} 가입 수락 완료');
            await _refreshTeam(_teamId!);
          }),
          _button('거절', () async {
            final id = _number(_requestNumber, '신청 번호');
            if (!await _confirm('신청 번호 $id 가입을 거절할까요?')) return;
            await _repo.rejectJoin(_teamId!, id);
            _receipt('가입 신청 $id 거절 완료');
            await _refreshTeam(_teamId!);
          }),
        ]) else _button('신청 취소', () async {
          final id = _number(_requestNumber, '신청 번호');
          if (!await _confirm('가입 신청 $id 번을 취소할까요?')) return;
          await _repo.cancelJoin(_teamId!, id);
          _receipt('가입 신청 $id 취소 완료');
        }),
      ]),
      if (_leader) _card('팀장 설정', [
        const Text('팀 이름 변경은 위의 팀 이름 입력란에 새 이름을 적은 뒤 눌러주세요.'),
        _button('팀 이름 변경', () async {
          await _repo.renameTeam(_teamId!, _name());
          _receipt('팀 이름 변경 완료');
          await _refreshTeam(_teamId!);
        }),
        const SizedBox(height: 16),
        _field(_memberNumber, '대상 회원 번호', number: true),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _button('팀장 위임', () async {
            final id = _number(_memberNumber, '회원 번호');
            if (!await _confirm('회원 번호 $id 님에게 팀장을 위임할까요?')) return;
            await _repo.transferLeader(_teamId!, id);
            _receipt('회원 번호 $id 님에게 팀장 위임 완료');
            await _refreshTeam(_teamId!);
          }),
          _button('팀원 내보내기', () async {
            final id = _number(_memberNumber, '회원 번호');
            if (!await _confirm('회원 번호 $id 님을 팀에서 내보낼까요?')) return;
            await _repo.kick(_teamId!, id);
            _receipt('회원 번호 $id 팀원 내보내기 완료');
            await _refreshTeam(_teamId!);
          }),
        ]),
      ]),
    ],
  ]);

  Future<void> _requestMatch(int id) async {
    if (!await _confirm('경기 번호 $id 번에 참가 신청할까요?')) return;
    final r = await _repo.requestMatch(id);
    _receipt('참가 신청 완료 · ${r['homeTeamName']} vs ${r['awayTeamName']} · 경기 번호 ${r['matchId']} · 신청 번호 ${r['requestId']}');
  }

  Widget _matches() => Column(children: [
    _choices(['우리 팀', '전체 팀'], _matchScope, (value) {
      setState(() => _matchScope = value);
      if (value == 0) _run(_loadMyTeam);
    }),
    if (_matchScope == 0 && (_myTeamLoading || _myTeam == null)) _myTeamStatus()
    else FootmatchMatchList(
      key: ValueKey('matches-${_matchScope == 0 ? _myTeamId : 'all'}'),
      teamId: _matchScope == 0 ? _myTeamId : null,
      revision: _matchRevision,
      onRequest: _matchScope == 1 ? (match) => _run(() => _requestMatch(match.id)) : null,
    ),
    _card('경기 등록', [
      if (!_myTeamLeader) const Text('소속 팀의 팀장이 경기를 등록할 수 있어요.') else ...[
        Text('홈 팀: ${_myTeam!['teamName']}'),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: _busy ? null : _pickDate,
            child: Text(_playedAt == null ? '경기 날짜와 시간 선택'
                : _playedAt!.toString().substring(0, 16))),
        _button('경기 등록', () async {
          if (_playedAt == null || !_playedAt!.isAfter(DateTime.now())) {
            throw const ApiException('현재보다 나중인 경기 시간을 선택해주세요.');
          }
          final r = await _repo.createMatch(_myTeamId!, _playedAt!);
          _receipt('경기 등록 완료 · 경기 번호 ${r['matchId']} · ${r['homeTeamName']} · ${r['playedAt']}');
          if (mounted) setState(() { _playedAt = null; _matchRevision++; });
        }),
      ],
    ]),
    _card('경기 참가 신청', [
      const Text('상대 팀에게 전달받은 경기 번호를 입력하세요. 소속 팀의 팀장이 신청할 수 있어요.'),
      const SizedBox(height: 12), _field(_matchNumber, '경기 번호', number: true),
      _button('참가 신청', () async {
        final id = _number(_matchNumber, '경기 번호');
        await _requestMatch(id);
      }),
    ]),
    if (_myTeamLeader) _card('경기 참가 신청 수락', [
      const Text('위 경기 번호 입력란에 우리 팀이 등록한 경기 번호를 적고, 상대 팀에게 전달받은 신청 번호를 입력하세요.'),
      const SizedBox(height: 12),
      _field(_matchRequestNumber, '경기 참가 신청 번호', number: true),
      _button('경기 신청 수락', () async {
        final matchId = _number(_matchNumber, '경기 번호');
        final requestId = _number(_matchRequestNumber, '경기 참가 신청 번호');
        if (!await _confirm('경기 $matchId 번의 신청 $requestId 번을 수락할까요?')) return;
        await _repo.acceptMatch(matchId, requestId);
        _receipt('경기 $matchId 매칭 완료');
        if (mounted) setState(() { _matchRevision++; _matchRequestNumber.clear(); });
      }),
    ]),
    _card('경기 번호 보관', const [
      Text('등록·신청 결과는 회원 → 내 정보의 처리 내역에서 복사할 수 있어요.\n'
          '경기 신청을 수락하면 진행 중 목록에서 확인할 수 있어요.'),
    ]),
  ]);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Footmatch'), actions: [
      IconButton(tooltip: '로그아웃', onPressed: _busy ? null : () async {
        await ref.read(authControllerProvider.notifier).logout();
      }, icon: const Icon(Icons.logout)),
    ]),
    body: SafeArea(child: Column(children: [
      if (_busy) const LinearProgressIndicator(),
      if (_error != null) MaterialBanner(content: Text(_error!), actions: [
        TextButton(onPressed: () => setState(() => _error = null), child: const Text('닫기')),
      ]),
      Expanded(child: IgnorePointer(ignoring: _busy, child: SingleChildScrollView(
        key: ValueKey(_tab), padding: const EdgeInsets.all(16),
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760),
          child: switch (_tab) { 1 => _teamTab(), 2 => _matches(), _ => _memberTab() },
        )),
      ))),
    ])),
    bottomNavigationBar: NavigationBar(selectedIndex: _tab,
      onDestinationSelected: _busy ? null : (value) {
        setState(() => _tab = value);
        if (value == 2) _run(_loadMyTeam);
        if (value == 1 && _teamView == 1) _run(_openMyTeam);
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.person_outline), label: '회원'),
        NavigationDestination(icon: Icon(Icons.groups_outlined), label: '팀'),
        NavigationDestination(icon: Icon(Icons.sports_soccer), label: '경기'),
      ],
    ),
  );
}
