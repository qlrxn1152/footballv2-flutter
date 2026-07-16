import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../data/team_post_comment.dart';
import '../data/team_post_repository.dart';

class TeamPostCommentsSection extends ConsumerStatefulWidget {
  const TeamPostCommentsSection({
    required this.teamId,
    required this.postId,
    required this.currentMemberId,
    super.key,
  });

  final int teamId;
  final int postId;
  final int currentMemberId;

  @override
  ConsumerState<TeamPostCommentsSection> createState() =>
      _TeamPostCommentsSectionState();
}

class _TeamPostCommentsSectionState
    extends ConsumerState<TeamPostCommentsSection> {
  final _controller = TextEditingController();
  bool _submitting = false;

  TeamPostQuery get _query => (
    teamId: widget.teamId,
    postId: widget.postId,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (_submitting || content.isEmpty) {
      if (content.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글 내용을 입력해주세요.')),
        );
      }
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref
          .read(teamPostRepositoryProvider)
          .createComment(widget.teamId, widget.postId, content);
      if (!mounted) return;
      _controller.clear();
      ref.invalidate(teamPostCommentsProvider(_query));
      await ref.read(teamPostCommentsProvider(_query).future);
      if (!mounted) return;
      FocusScope.of(context).unfocus();
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : '댓글을 등록하지 못했습니다.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(teamPostCommentsProvider(_query));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '댓글',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            comments.when(
              data: (items) => Text(
                '${items.length}',
                style: const TextStyle(
                  color: AppTheme.fieldGreen,
                  fontWeight: FontWeight.w900,
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        comments.when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, _) => _CommentError(
            message: error is ApiException ? error.message : error.toString(),
            onRetry: () => ref.invalidate(teamPostCommentsProvider(_query)),
          ),
          data: (items) => items.isEmpty
              ? const _EmptyComments()
              : Column(
                  children: [
                    for (final comment in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CommentCard(
                          comment: comment,
                          isMine:
                              comment.authorMemberId == widget.currentMemberId,
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 14),
        TextField(
          key: const ValueKey('team-post-comment-field'),
          controller: _controller,
          minLines: 2,
          maxLines: 5,
          maxLength: 1000,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            labelText: '댓글 작성',
            hintText: '팀원들과 의견을 나눠보세요.',
            alignLabelWithHint: true,
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: IconButton.filled(
                key: const ValueKey('team-post-comment-submit-button'),
                onPressed: _submitting ? null : _submit,
                tooltip: '댓글 등록',
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment, required this.isMine});

  final TeamPostComment comment;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMine
            ? AppTheme.lime.withValues(alpha: 0.18)
            : Colors.white,
        border: Border.all(color: AppTheme.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.fieldGreen.withValues(alpha: 0.1),
            child: Text(
              _initial(comment.authorUsername),
              style: const TextStyle(
                color: AppTheme.fieldGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.authorUsername,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 6),
                      const Text(
                        '내 댓글',
                        style: TextStyle(
                          color: AppTheme.fieldGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      _formatDateTime(comment.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  comment.content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyComments extends StatelessWidget {
  const _EmptyComments();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 20),
          SizedBox(width: 8),
          Text('첫 번째 댓글을 남겨보세요.'),
        ],
      ),
    );
  }
}

class _CommentError extends StatelessWidget {
  const _CommentError({required this.message, required this.onRetry});

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
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('댓글 다시 불러오기'),
            ),
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

String _formatDateTime(DateTime? value) {
  if (value == null) return '-';
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$month.$day $hour:$minute';
}
