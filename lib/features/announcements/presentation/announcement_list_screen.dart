import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/presentation/home_navigation.dart';
import '../../members/data/member_repository.dart';
import '../data/announcement.dart';
import '../data/announcement_repository.dart';
import 'announcement_create_screen.dart';
import 'announcement_detail_screen.dart';

class AnnouncementListScreen extends ConsumerWidget {
  const AnnouncementListScreen({super.key});

  Future<void> _openCreate(BuildContext context, WidgetRef ref) async {
    final created = await Navigator.of(context).push<AnnouncementDetail>(
      MaterialPageRoute(builder: (_) => const AnnouncementCreateScreen()),
    );
    if (created == null || !context.mounted) return;
    ref.invalidate(announcementsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('공지사항 “${created.title}”을 등록했습니다.')),
    );
  }

  Future<void> _openDetail(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => AnnouncementDetailScreen(id: id)),
    );
    ref.invalidate(announcementsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements = ref.watch(announcementsProvider);
    final isAdmin = ref.watch(memberMeProvider).when(
      data: (member) => member.isAdmin,
      error: (_, _) => false,
      loading: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('공지사항'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(announcementsProvider),
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      bottomNavigationBar: const FootballPageNavigationBar(),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              key: const ValueKey('announcement-create-button'),
              onPressed: () => _openCreate(context, ref),
              icon: const Icon(Icons.edit_note_outlined),
              label: const Text('관리자 작성'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(announcementsProvider);
          await ref.read(announcementsProvider.future);
        },
        child: announcements.when(
          loading: () => const _LoadingList(),
          error: (error, _) => _ErrorList(
            message: error is ApiException ? error.message : error.toString(),
            onRetry: () => ref.invalidate(announcementsProvider),
          ),
          data: (items) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 92),
            children: [
              const _AnnouncementHeader(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    '새 소식',
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
                const _EmptyAnnouncementsCard()
              else
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AnnouncementCard(
                      announcement: item,
                      onTap: () => _openDetail(
                        context,
                        ref,
                        item.announcementId,
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

class _AnnouncementHeader extends StatelessWidget {
  const _AnnouncementHeader();

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
      child: const Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: AppTheme.lime,
            child: Icon(Icons.campaign_outlined, color: AppTheme.navy),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '풋볼로그 새 소식',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '운영 안내와 업데이트 소식을 확인하세요.',
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

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.announcement,
    required this.onTap,
  });

  final AnnouncementSummary announcement;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TypeIcon(type: announcement.type),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _TypeChip(type: announcement.type),
                        if (announcement.pinned) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.push_pin,
                            size: 16,
                            color: Color(0xFFF08C00),
                          ),
                          const SizedBox(width: 2),
                          const Text(
                            '고정',
                            style: TextStyle(
                              color: Color(0xFFF08C00),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      announcement.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 3,
                      children: [
                        Text(
                          announcement.authorUsername,
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          _formatDate(announcement.createdAt),
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (_hasText(announcement.version))
                          Text(
                            'v${announcement.version}',
                            style: const TextStyle(
                              color: AppTheme.fieldGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Icon(Icons.chevron_right, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type});

  final AnnouncementType type;

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(type);
    final icon = switch (type) {
      AnnouncementType.notice => Icons.campaign_outlined,
      AnnouncementType.update => Icons.auto_awesome_outlined,
      AnnouncementType.maintenance => Icons.build_outlined,
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final AnnouncementType type;

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        type.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyAnnouncementsCard extends StatelessWidget {
  const _EmptyAnnouncementsCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(Icons.notifications_none, size: 42),
            SizedBox(height: 10),
            Text('등록된 공지사항이 없습니다.'),
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

Color _typeColor(AnnouncementType type) {
  return switch (type) {
    AnnouncementType.notice => const Color(0xFF1971C2),
    AnnouncementType.update => AppTheme.fieldGreen,
    AnnouncementType.maintenance => const Color(0xFFF08C00),
  };
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

String _formatDate(DateTime? value) {
  if (value == null) return '-';
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}.$month.$day';
}
