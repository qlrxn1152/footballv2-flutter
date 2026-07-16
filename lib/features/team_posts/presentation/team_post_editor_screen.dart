import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/team_post.dart';
import '../data/team_post_repository.dart';

class TeamPostEditorScreen extends ConsumerStatefulWidget {
  const TeamPostEditorScreen({
    required this.teamId,
    this.initial,
    super.key,
  });

  final int teamId;
  final TeamPostDetail? initial;

  @override
  ConsumerState<TeamPostEditorScreen> createState() =>
      _TeamPostEditorScreenState();
}

class _TeamPostEditorScreenState extends ConsumerState<TeamPostEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _submitting = false;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) return;
    _titleController.text = initial.title;
    _contentController.text = initial.content;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final input = TeamPostInput(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
      );
      final repository = ref.read(teamPostRepositoryProvider);
      final saved = _editing
          ? await repository.updatePost(
              widget.teamId,
              widget.initial!.postId,
              input,
            )
          : await repository.createPost(widget.teamId, input);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : _editing
          ? '게시글을 수정하지 못했습니다.'
          : '게시글을 등록하지 못했습니다.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? '게시글 수정' : '게시글 작성')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.groups_outlined),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '이 게시글은 같은 팀의 멤버만 확인할 수 있습니다.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              key: const ValueKey('team-post-title-field'),
              controller: _titleController,
              maxLength: 100,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '제목',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? '제목을 입력해주세요.'
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const ValueKey('team-post-content-field'),
              controller: _contentController,
              minLines: 10,
              maxLines: 18,
              maxLength: 5000,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: '내용',
                alignLabelWithHint: true,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? '내용을 입력해주세요.'
                  : null,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey('team-post-submit-button'),
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_editing ? Icons.save_outlined : Icons.send_outlined),
              label: Text(_editing ? '변경사항 저장' : '게시글 등록'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
