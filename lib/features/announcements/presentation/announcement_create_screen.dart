import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/announcement.dart';
import '../data/announcement_repository.dart';

class AnnouncementCreateScreen extends ConsumerStatefulWidget {
  const AnnouncementCreateScreen({this.initial, super.key});

  final AnnouncementDetail? initial;

  @override
  ConsumerState<AnnouncementCreateScreen> createState() =>
      _AnnouncementCreateScreenState();
}

class _AnnouncementCreateScreenState
    extends ConsumerState<AnnouncementCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _versionController = TextEditingController();
  AnnouncementType _type = AnnouncementType.notice;
  bool _pinned = false;
  bool _submitting = false;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) return;
    _type = initial.type;
    _titleController.text = initial.title;
    _contentController.text = initial.content;
    _versionController.text = initial.version ?? '';
    _pinned = initial.pinned;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _versionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final version = _versionController.text.trim();
      final input = AnnouncementCreateInput(
        type: _type,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        version: version.isEmpty ? null : version,
        pinned: _pinned,
      );
      final repository = ref.read(announcementRepositoryProvider);
      final saved = _editing
          ? await repository.updateAnnouncement(widget.initial!.id, input)
          : await repository.createAnnouncement(input);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (error) {
      if (!mounted) return;
      final fallbackMessage = _editing
          ? '공지사항을 수정하지 못했습니다.'
          : '공지사항을 등록하지 못했습니다.';
      final message = error is ApiException
          ? error.message
          : fallbackMessage;
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
      appBar: AppBar(
        title: Text(_editing ? '관리자 공지 수정' : '관리자 공지 작성'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '관리자 권한이 있는 계정만 공지사항을 ${_editing ? '수정' : '등록'}할 수 있습니다.',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<AnnouncementType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: '공지 유형',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: AnnouncementType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '제목',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? '제목을 입력해주세요.'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _versionController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '버전 (선택)',
                hintText: '예: 1.1.0',
                prefixIcon: Icon(Icons.new_releases_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _contentController,
              minLines: 8,
              maxLines: 16,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: '내용',
                alignLabelWithHint: true,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? '내용을 입력해주세요.'
                  : null,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _pinned,
              onChanged: (value) => setState(() => _pinned = value),
              title: const Text(
                '상단 고정',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('중요한 공지라면 목록 맨 위에 표시합니다.'),
              secondary: const Icon(Icons.push_pin_outlined),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _editing ? Icons.save_outlined : Icons.send_outlined,
                    ),
              label: Text(_editing ? '변경사항 저장' : '공지사항 등록'),
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
