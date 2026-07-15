import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/network/api_client.dart';
import 'package:footballv2_flutter/core/session/auth_session.dart';
import 'package:footballv2_flutter/core/session/session_store.dart';
import 'package:footballv2_flutter/features/announcements/data/announcement.dart';
import 'package:footballv2_flutter/features/announcements/data/announcement_repository.dart';

void main() {
  test('공지사항 목록을 고정 우선, 최신순으로 조회한다', () async {
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
                  'announcementId': 1,
                  'type': 'NOTICE',
                  'title': '일반 공지',
                  'version': null,
                  'pinned': false,
                  'authorUsername': 'admin',
                  'createdAt': '2026-07-15T21:00:00',
                },
                {
                  'announcementId': 2,
                  'type': 'UPDATE',
                  'title': '고정 공지',
                  'version': '1.1.0',
                  'pinned': true,
                  'authorUsername': 'admin',
                  'createdAt': '2026-07-15T20:00:00',
                },
              ],
            ),
          );
        },
      ),
    );

    final result = await AnnouncementRepository(
      apiClient,
    ).fetchAnnouncements();

    expect(capturedRequest?.method, 'GET');
    expect(capturedRequest?.path, '/api/announcements');
    expect(result.map((item) => item.announcementId), [2, 1]);
  });

  test('관리자 공지사항 작성 요청을 전송한다', () async {
    final apiClient = ApiClient(_EmptySessionStore());
    RequestOptions? capturedRequest;
    apiClient.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 201,
              data: {
                'id': 9,
                'announcementType': 'NOTICE',
                'title': '운영 안내',
                'content': '공지 내용',
                'version': null,
                'pinned': true,
              },
            ),
          );
        },
      ),
    );

    final result = await AnnouncementRepository(apiClient).createAnnouncement(
      const AnnouncementCreateInput(
        type: AnnouncementType.notice,
        title: '운영 안내',
        content: '공지 내용',
        version: null,
        pinned: true,
      ),
    );

    expect(capturedRequest?.method, 'POST');
    expect(capturedRequest?.path, '/api/admin/announcements');
    expect(capturedRequest?.data, {
      'announcementType': 'NOTICE',
      'title': '운영 안내',
      'content': '공지 내용',
      'version': null,
      'pinned': true,
    });
    expect(result.id, 9);
  });

  test('관리자 공지사항 수정 요청을 JSON으로 전송한다', () async {
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
              data: {
                'id': 9,
                'announcementType': 'UPDATE',
                'title': '기능 업데이트',
                'content': '수정된 공지 내용',
                'version': '1.2.0',
                'pinned': false,
              },
            ),
          );
        },
      ),
    );

    final result = await AnnouncementRepository(apiClient).updateAnnouncement(
      9,
      const AnnouncementCreateInput(
        type: AnnouncementType.update,
        title: '기능 업데이트',
        content: '수정된 공지 내용',
        version: '1.2.0',
        pinned: false,
      ),
    );

    expect(capturedRequest?.method, 'PUT');
    expect(capturedRequest?.path, '/api/admin/announcements/9');
    expect(capturedRequest?.data, {
      'announcementType': 'UPDATE',
      'title': '기능 업데이트',
      'content': '수정된 공지 내용',
      'version': '1.2.0',
      'pinned': false,
    });
    expect(result.title, '기능 업데이트');
  });

  test('관리자 공지사항 삭제 요청을 전송한다', () async {
    final apiClient = ApiClient(_EmptySessionStore());
    RequestOptions? capturedRequest;
    apiClient.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.resolve(
            Response<void>(
              requestOptions: options,
              statusCode: 204,
            ),
          );
        },
      ),
    );

    await AnnouncementRepository(apiClient).deleteAnnouncement(9);

    expect(capturedRequest?.method, 'DELETE');
    expect(capturedRequest?.path, '/api/admin/announcements/9');
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
