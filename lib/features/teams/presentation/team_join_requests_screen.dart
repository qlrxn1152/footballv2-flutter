import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/team_models.dart';
import '../data/team_repository.dart';

class TeamJoinRequestsScreen extends ConsumerStatefulWidget {
  const TeamJoinRequestsScreen({
    required this.teamId,
    required this.teamName,
    super.key,
  });

  final int teamId;
  final String teamName;

  @override
  ConsumerState<TeamJoinRequestsScreen> createState() =>
      _TeamJoinRequestsScreenState();
}

class _TeamJoinRequestsScreenState
    extends ConsumerState<TeamJoinRequestsScreen> {
  String _status = 'PENDING';
  final Set<int> _busyRequestIds = {};

  JoinRequestQuery get _query => (teamId: widget.teamId, status: _status);

  Future<void> _decide(TeamJoinRequest request, bool accept) async {
    setState(() => _busyRequestIds.add(request.teamJoinRequestId));
    try {
      await ref.read(teamRepositoryProvider).decideJoinRequest(
        teamId: widget.teamId,
        requestId: request.teamJoinRequestId,
        accept: accept,
      );
      ref.invalidate(joinRequestsProvider(_query));
      ref.invalidate(teamMembersProvider(widget.teamId));
      ref.invalidate(teamDetailProvider(widget.teamId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accept ? '가입 신청을 수락했습니다.' : '가입 신청을 거절했습니다.')),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : '가입 신청을 처리하지 못했습니다.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _busyRequestIds.remove(request.teamJoinRequestId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(joinRequestsProvider(_query));

    return Scaffold(
      appBar: AppBar(title: Text('${widget.teamName} 가입 신청')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'PENDING', label: Text('대기')),
                ButtonSegment(value: 'ACCEPT', label: Text('수락')),
                ButtonSegment(value: 'REJECT', label: Text('거절')),
              ],
              selected: {_status},
              onSelectionChanged: (selected) {
                setState(() => _status = selected.first);
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.refresh(joinRequestsProvider(_query).future);
              },
              child: requests.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(32),
                  children: [
                    const SizedBox(height: 100),
                    Text(error.toString(), textAlign: TextAlign.center),
                  ],
                ),
                data: (items) => items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 130),
                          Icon(Icons.inbox_outlined, size: 54),
                          SizedBox(height: 14),
                          Text('해당 상태의 가입 신청이 없습니다.',
                              textAlign: TextAlign.center),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final request = items[index];
                          return _RequestCard(
                            request: request,
                            busy: _busyRequestIds.contains(
                              request.teamJoinRequestId,
                            ),
                            onAccept: () => _decide(request, true),
                            onReject: () => _decide(request, false),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  final TeamJoinRequest request;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person_outline)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.username,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text('회원 번호 ${request.memberId}'),
                    ],
                  ),
                ),
                _StatusChip(status: request.status),
              ],
            ),
            if (request.status == 'PENDING') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : onReject,
                      child: const Text('거절'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: busy ? null : onAccept,
                      child: busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('수락'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'ACCEPT' => ('수락', const Color(0xFF087F5B)),
      'REJECT' => ('거절', Theme.of(context).colorScheme.error),
      _ => ('대기', const Color(0xFFF08C00)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}
