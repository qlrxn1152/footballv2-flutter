import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/network/api_client.dart';
import 'package:footballv2_flutter/core/session/auth_session.dart';
import 'package:footballv2_flutter/core/session/session_store.dart';
import 'package:footballv2_flutter/features/notifications/data/member_notification.dart';
import 'package:footballv2_flutter/features/notifications/data/member_notification_repository.dart';

void main() {
  test('매치 성사 알림 응답을 변환한다', () {
    final notification = MemberNotification.fromJson({
      'notificationId': 11,
      'type': 'MATCH_ACCEPTED',
      'title': '매치가 성사됐습니다.',
      'content': '매치 성사 완료',
      'referenceId': 23,
      'read': false,
      'createdAt': '2026-07-17T12:30:00',
    });

    expect(notification.notificationId, 11);
    expect(notification.isUnread, isTrue);
    expect(notification.opensMatch, isTrue);
    expect(notification.referenceId, 23);
  });

  test('알림 목록을 최신순으로 조회한다', () async {
    final apiClient = ApiClient(_EmptySessionStore());
    RequestOptions? capturedRequest;
    apiClient.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 200,
              data: [
                {
                  'notificationId': 1,
                  'type': 'MATCH_ACCEPTED',
                  'title': '먼저 온 알림',
                  'content': '',
                  'referenceId': 20,
                  'read': true,
                  'createdAt': '2026-07-17T10:00:00',
                },
                {
                  'notificationId': 2,
                  'type': 'MATCH_ACCEPTED',
                  'title': '나중에 온 알림',
                  'content': '',
                  'referenceId': 21,
                  'read': false,
                  'createdAt': '2026-07-17T11:00:00',
                },
              ],
            ),
          );
        },
      ),
    );

    final result = await MemberNotificationRepository(
      apiClient,
    ).fetchNotifications();

    expect(capturedRequest?.method, 'GET');
    expect(capturedRequest?.path, '/api/notifications');
    expect(result.map((item) => item.notificationId), [2, 1]);
  });

  test('읽지 않은 알림 개수와 읽음 처리 API를 호출한다', () async {
    final apiClient = ApiClient(_EmptySessionStore());
    final requests = <RequestOptions>[];
    apiClient.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          if (options.path.endsWith('/unread-count')) {
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                statusCode: 200,
                data: {'count': 3},
              ),
            );
            return;
          }
          handler.resolve(
            Response<void>(requestOptions: options, statusCode: 204),
          );
        },
      ),
    );
    final repository = MemberNotificationRepository(apiClient);

    expect(await repository.fetchUnreadCount(), 3);
    await repository.markAsRead(11);

    expect(requests[0].method, 'GET');
    expect(requests[0].path, '/api/notifications/unread-count');
    expect(requests[1].method, 'PATCH');
    expect(requests[1].path, '/api/notifications/11/read');
  });
}

class _EmptySessionStore implements SessionStore {
  @override
  Future<void> clear() async {}

  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> save(AuthSession session) async {}
}
