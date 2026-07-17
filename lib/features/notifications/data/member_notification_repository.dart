import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'member_notification.dart';

class MemberNotificationRepository {
  const MemberNotificationRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<MemberNotification>> fetchNotifications() {
    return runApi(() async {
      final response = await _apiClient.dio.get<Object?>(
        '/api/notifications',
      );
      final data = response.data;
      if (data is! List) {
        throw const ApiException('알림 목록 응답 형식이 올바르지 않습니다.');
      }

      final notifications = data
          .map((item) => MemberNotification.fromJson(jsonMap(item)))
          .toList(growable: true);
      notifications.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return notifications;
    });
  }

  Future<int> fetchUnreadCount() {
    return runApi(() async {
      final response = await _apiClient.dio.get<Object?>(
        '/api/notifications/unread-count',
      );
      final count = jsonMap(response.data)['count'];
      if (count is! num) {
        throw const ApiException('읽지 않은 알림 개수 응답 형식이 올바르지 않습니다.');
      }
      return count.toInt();
    });
  }

  Future<void> markAsRead(int notificationId) {
    return runApi(() async {
      await _apiClient.dio.patch<void>(
        '/api/notifications/$notificationId/read',
      );
    });
  }
}

final memberNotificationRepositoryProvider =
    Provider<MemberNotificationRepository>(
      (ref) => MemberNotificationRepository(ref.watch(apiClientProvider)),
    );

final memberNotificationsProvider = FutureProvider<List<MemberNotification>>(
  (ref) => ref.watch(memberNotificationRepositoryProvider).fetchNotifications(),
);

final unreadNotificationCountProvider = FutureProvider<int>(
  (ref) => ref
      .watch(memberNotificationRepositoryProvider)
      .fetchUnreadCount(),
);
