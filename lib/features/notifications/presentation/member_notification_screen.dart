import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/presentation/home_navigation.dart';
import '../../matches/presentation/team_match_detail_screen.dart';
import '../data/member_notification.dart';
import '../data/member_notification_repository.dart';

class MemberNotificationScreen extends ConsumerStatefulWidget {
  const MemberNotificationScreen({super.key});

  @override
  ConsumerState<MemberNotificationScreen> createState() =>
      _MemberNotificationScreenState();
}

class _MemberNotificationScreenState
    extends ConsumerState<MemberNotificationScreen> {
  final Set<int> _processingIds = {};

  Future<void> _refresh() async {
    ref.invalidate(memberNotificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);
    await ref.read(memberNotificationsProvider.future);
  }

  Future<void> _openNotification(MemberNotification notification) async {
    if (_processingIds.contains(notification.notificationId)) return;
    setState(() => _processingIds.add(notification.notificationId));

    try {
      if (notification.isUnread) {
        await ref
            .read(memberNotificationRepositoryProvider)
            .markAsRead(notification.notificationId);
        ref.invalidate(memberNotificationsProvider);
        ref.invalidate(unreadNotificationCountProvider);
      }

      if (!mounted) return;
      final matchId = notification.referenceId;
      if (notification.opensMatch && matchId != null) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => TeamMatchDetailScreen(teamMatchId: matchId),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : '알림을 처리하지 못했습니다.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(notification.notificationId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(memberNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          IconButton(
            onPressed: () => _refresh(),
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      bottomNavigationBar: const FootballPageNavigationBar(),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: notifications.when(
          loading: () => const _NotificationLoading(),
          error: (error, _) => _NotificationError(
            message: error is ApiException ? error.message : error.toString(),
            onRetry: () => ref.invalidate(memberNotificationsProvider),
          ),
          data: (items) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const _NotificationHeader(),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    '내 알림',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Text('${items.length}건'),
                ],
              ),
              const SizedBox(height: 10),
              if (items.isEmpty)
                const _EmptyNotifications()
              else
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _NotificationCard(
                      notification: item,
                      isProcessing: _processingIds.contains(
                        item.notificationId,
                      ),
                      onTap: () => _openNotification(item),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationHeader extends StatelessWidget {
  const _NotificationHeader();

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
            child: Icon(Icons.notifications_outlined, color: AppTheme.navy),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '경기 소식을 확인하세요',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '매치가 성사되면 이곳에서 바로 알려드려요.',
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

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.isProcessing,
    required this.onTap,
  });

  final MemberNotification notification;
  final bool isProcessing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = notification.isUnread;
    return Card(
      color: unread ? const Color(0xFFF2FBE0) : Colors.white,
      child: InkWell(
        key: ValueKey('notification-${notification.notificationId}'),
        onTap: isProcessing ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 23,
                    backgroundColor: unread
                        ? AppTheme.lime
                        : const Color(0xFFEAF0ED),
                    child: const Icon(
                      Icons.handshake_outlined,
                      color: AppTheme.navy,
                    ),
                  ),
                  if (unread)
                    const Positioned(
                      right: -1,
                      top: -1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFE03131),
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox(width: 10, height: 10),
                      ),
                    ),
                ],
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
                            notification.title,
                            style: TextStyle(
                              fontWeight: unread
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isProcessing)
                          const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if (notification.opensMatch)
                          const Icon(Icons.chevron_right),
                      ],
                    ),
                    if (notification.content.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        notification.content,
                        style: const TextStyle(color: Color(0xFF58675F)),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _formatDateTime(notification.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF75827C),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 42),
        child: Column(
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 48,
              color: Color(0xFF75827C),
            ),
            SizedBox(height: 12),
            Text(
              '아직 받은 알림이 없습니다.',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationLoading extends StatelessWidget {
  const _NotificationLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _NotificationError extends StatelessWidget {
  const _NotificationError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.error_outline, size: 48),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    );
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}.${two(local.month)}.${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
