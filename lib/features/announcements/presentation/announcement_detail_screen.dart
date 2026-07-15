import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../data/announcement.dart';
import '../data/announcement_repository.dart';
import 'announcement_create_screen.dart';

enum _AnnouncementAdminAction { edit, delete }

class AnnouncementDetailScreen extends ConsumerWidget {
  const AnnouncementDetailScreen({required this.id, super.key});

  final int id;

  Future<void> _openEdit(
    BuildContext context,
    WidgetRef ref,
    AnnouncementDetail item,
  ) async {
    final updated = await Navigator.of(context).push<AnnouncementDetail>(
      MaterialPageRoute(
        builder: (_) => AnnouncementCreateScreen(initial: item),
      ),
    );
    if (updated == null || !context.mounted) return;
    ref.invalidate(announcementDetailProvider(id));
    ref.invalidate(announcementsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('공지사항 “${updated.title}”을 수정했습니다.')),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('공지사항 삭제'),
        content: const Text('삭제한 공지사항은 복구할 수 없습니다. 정말 삭제할까요?'),
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
      await ref.read(announcementRepositoryProvider).deleteAnnouncement(id);
      if (!context.mounted) return;
      ref.invalidate(announcementsProvider);
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('공지사항을 삭제했습니다.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      final message = error is ApiException
          ? error.message
          : '공지사항을 삭제하지 못했습니다.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(announcementDetailProvider(id));

    return detail.when(
      loading: () => const Scaffold(
        appBar: _AnnouncementDetailAppBar(),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: const _AnnouncementDetailAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 48),
                const SizedBox(height: 12),
                Text(
                  error is ApiException ? error.message : error.toString(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(
                    announcementDetailProvider(id),
                  ),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (item) => Scaffold(
        appBar: AppBar(
          title: const Text('공지사항 상세'),
          actions: [
            PopupMenuButton<_AnnouncementAdminAction>(
              key: const ValueKey('announcement-admin-menu'),
              tooltip: '관리자 기능',
              onSelected: (action) async {
                switch (action) {
                  case _AnnouncementAdminAction.edit:
                    await _openEdit(context, ref, item);
                  case _AnnouncementAdminAction.delete:
                    await _delete(context, ref);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _AnnouncementAdminAction.edit,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('공지 수정'),
                  ),
                ),
                PopupMenuItem(
                  value: _AnnouncementAdminAction.delete,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline),
                    title: Text('공지 삭제'),
                  ),
                ),
              ],
              icon: const Icon(Icons.admin_panel_settings_outlined),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                _DetailTypeChip(type: item.type),
                if (item.pinned) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.push_pin,
                    color: Color(0xFFF08C00),
                    size: 18,
                  ),
                  const Text(
                    '고정 공지',
                    style: TextStyle(
                      color: Color(0xFFF08C00),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const Spacer(),
                if (item.version != null && item.version!.trim().isNotEmpty)
                  Text(
                    'v${item.version}',
                    style: const TextStyle(
                      color: AppTheme.fieldGreen,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              item.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 18),
            SelectableText(
              item.content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.75,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _AnnouncementDetailAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('공지사항 상세'));
  }
}

class _DetailTypeChip extends StatelessWidget {
  const _DetailTypeChip({required this.type});

  final AnnouncementType type;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      AnnouncementType.notice => const Color(0xFF1971C2),
      AnnouncementType.update => AppTheme.fieldGreen,
      AnnouncementType.maintenance => const Color(0xFFF08C00),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        type.label,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}
