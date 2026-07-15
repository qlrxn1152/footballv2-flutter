import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../data/announcement.dart';
import '../data/announcement_repository.dart';

class AnnouncementDetailScreen extends ConsumerWidget {
  const AnnouncementDetailScreen({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(announcementDetailProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('공지사항 상세')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
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
        data: (item) => ListView(
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
