import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../data/team_post.dart';
import '../data/team_post_repository.dart';
import 'team_post_editor_screen.dart';

enum _TeamPostAction { edit, delete }

class TeamPostDetailScreen extends ConsumerWidget {
  const TeamPostDetailScreen({
    required this.teamId,
    required this.postId,
    required this.currentMemberId,
    super.key,
  });

  final int teamId;
  final int postId;
  final int currentMemberId;

  TeamPostQuery get _query => (teamId: teamId, postId: postId);

  Future<void> _openEdit(
    BuildContext context,
    WidgetRef ref,
    TeamPostDetail post,
  ) async {
    final updated = await Navigator.of(context).push<TeamPostDetail>(
      MaterialPageRoute(
        builder: (_) => TeamPostEditorScreen(teamId: teamId, initial: post),
      ),
    );
    if (updated == null || !context.mounted) return;
    ref.invalidate(teamPostDetailProvider(_query));
    ref.invalidate(teamPostsProvider(teamId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('게시글을 수정했습니다.')),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('삭제한 게시글은 복구할 수 없습니다. 정말 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(teamPostRepositoryProvider).deletePost(teamId, postId);
      if (!context.mounted) return;
      ref.invalidate(teamPostsProvider(teamId));
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        const SnackBar(content: Text('게시글을 삭제했습니다.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      final message = error is ApiException
          ? error.message
          : '게시글을 삭제하지 못했습니다.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(teamPostDetailProvider(_query));

    return detail.when(
      loading: () => const Scaffold(
        appBar: _TeamPostDetailAppBar(),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: const _TeamPostDetailAppBar(),
        body: _ErrorView(
          message: error is ApiException ? error.message : error.toString(),
          onRetry: () => ref.invalidate(teamPostDetailProvider(_query)),
        ),
      ),
      data: (post) {
        final isAuthor = post.authorMemberId == currentMemberId;
        return Scaffold(
          appBar: AppBar(
            title: const Text('게시글 상세'),
            actions: [
              if (isAuthor)
                PopupMenuButton<_TeamPostAction>(
                  key: const ValueKey('team-post-author-menu'),
                  tooltip: '게시글 관리',
                  onSelected: (action) async {
                    switch (action) {
                      case _TeamPostAction.edit:
                        await _openEdit(context, ref, post);
                      case _TeamPostAction.delete:
                        await _delete(context, ref);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: _TeamPostAction.edit,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('게시글 수정'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _TeamPostAction.delete,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline),
                        title: Text('게시글 삭제'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: AppTheme.lime,
                    child: Text(
                      _initial(post.authorUsername),
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorUsername,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          _formatDateTime(post.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (_wasEdited(post))
                    const Text(
                      '수정됨',
                      style: TextStyle(
                        color: AppTheme.fieldGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                post.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 18),
              SelectableText(
                post.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.75,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TeamPostDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _TeamPostDetailAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('게시글 상세'));
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

String _initial(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
}

bool _wasEdited(TeamPostDetail post) {
  final createdAt = post.createdAt;
  final updatedAt = post.updatedAt;
  if (createdAt == null || updatedAt == null) return false;
  return updatedAt.difference(createdAt).inSeconds.abs() >= 1;
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '-';
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}.$month.$day $hour:$minute';
}
