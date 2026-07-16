import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../data/team_post.dart';
import '../data/team_post_repository.dart';
import 'team_post_detail_screen.dart';
import 'team_post_editor_screen.dart';

class TeamPostListScreen extends ConsumerWidget {
  const TeamPostListScreen({
    required this.teamId,
    required this.teamName,
    required this.currentMemberId,
    super.key,
  });

  final int teamId;
  final String teamName;
  final int currentMemberId;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(teamPostsProvider(teamId));
    await ref.read(teamPostsProvider(teamId).future);
  }

  Future<void> _openCreate(BuildContext context, WidgetRef ref) async {
    final created = await Navigator.of(context).push<TeamPostDetail>(
      MaterialPageRoute(
        builder: (_) => TeamPostEditorScreen(teamId: teamId),
      ),
    );
    if (created == null || !context.mounted) return;
    ref.invalidate(teamPostsProvider(teamId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('게시글을 등록했습니다.')),
    );
  }

  Future<void> _openDetail(
    BuildContext context,
    WidgetRef ref,
    int postId,
  ) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TeamPostDetailScreen(
          teamId: teamId,
          postId: postId,
          currentMemberId: currentMemberId,
        ),
      ),
    );
    ref.invalidate(teamPostsProvider(teamId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(teamPostsProvider(teamId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('팀 게시판'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(teamPostsProvider(teamId)),
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('team-post-create-button'),
        onPressed: () => _openCreate(context, ref),
        icon: const Icon(Icons.edit_note_outlined),
        label: const Text('글쓰기'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: posts.when(
          loading: () => const _LoadingList(),
          error: (error, _) => _ErrorList(
            message: error is ApiException ? error.message : error.toString(),
            onRetry: () => ref.invalidate(teamPostsProvider(teamId)),
          ),
          data: (items) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 92),
            children: [
              _BoardHeader(teamName: teamName),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    '최근 게시글',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text('${items.length}건'),
                ],
              ),
              const SizedBox(height: 10),
              if (items.isEmpty)
                const _EmptyPostsCard()
              else
                for (final post in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PostCard(
                      post: post,
                      isMine: post.authorMemberId == currentMemberId,
                      onTap: () => _openDetail(
                        context,
                        ref,
                        post.postId,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardHeader extends StatelessWidget {
  const _BoardHeader({required this.teamName});

  final String teamName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.navy, AppTheme.navySoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.lime,
            child: Icon(Icons.forum_outlined, color: AppTheme.navy),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$teamName 라커룸',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  '우리 팀 이야기와 일정을 자유롭게 나눠보세요.',
                  style: TextStyle(color: Color(0xFFBFD1D5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.isMine,
    required this.onTap,
  });

  final TeamPostSummary post;
  final bool isMine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.fieldGreen.withValues(alpha: 0.1),
                child: Text(
                  _initial(post.authorUsername),
                  style: const TextStyle(
                    color: AppTheme.fieldGreen,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            post.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.lime.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              '내 글',
                              style: TextStyle(
                                color: AppTheme.navy,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${post.authorUsername} · ${_formatDateTime(post.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 21),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPostsCard extends StatelessWidget {
  const _EmptyPostsCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline, size: 42),
            SizedBox(height: 10),
            Text('아직 등록된 게시글이 없습니다.'),
            SizedBox(height: 4),
            Text('첫 번째 팀 이야기를 남겨보세요.'),
          ],
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
        SizedBox(height: 220),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _ErrorList extends StatelessWidget {
  const _ErrorList({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.cloud_off_outlined, size: 48),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
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

String _initial(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '-';
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}.$month.$day $hour:$minute';
}
