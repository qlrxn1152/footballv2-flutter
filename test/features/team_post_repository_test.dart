import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/network/api_client.dart';
import 'package:footballv2_flutter/core/session/auth_session.dart';
import 'package:footballv2_flutter/core/session/session_store.dart';
import 'package:footballv2_flutter/features/team_posts/data/team_post.dart';
import 'package:footballv2_flutter/features/team_posts/data/team_post_repository.dart';

void main() {
  test('팀 게시글 목록을 최신순으로 조회한다', () async {
    final apiClient = ApiClient(_EmptySessionStore());
    RequestOptions? request;
    apiClient.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          request = options;
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 200,
              data: [
                _summaryJson(1, '2026-07-16T10:00:00'),
                _summaryJson(2, '2026-07-16T12:00:00'),
              ],
            ),
          );
        },
      ),
    );

    final posts = await TeamPostRepository(apiClient).fetchPosts(3);

    expect(request?.method, 'GET');
    expect(request?.path, '/api/teams/3/posts');
    expect(posts.map((post) => post.postId), [2, 1]);
  });

  test('팀 게시글 작성 요청을 전송한다', () async {
    final apiClient = ApiClient(_EmptySessionStore());
    RequestOptions? request;
    apiClient.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          request = options;
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 201,
              data: _detailJson(),
            ),
          );
        },
      ),
    );

    final post = await TeamPostRepository(apiClient).createPost(
      3,
      const TeamPostInput(title: '새 글', content: '새 내용'),
    );

    expect(request?.method, 'POST');
    expect(request?.path, '/api/teams/3/posts');
    expect(request?.data, {'title': '새 글', 'content': '새 내용'});
    expect(post.postId, 7);
  });

  test('팀 게시글 수정과 삭제 요청을 전송한다', () async {
    final apiClient = ApiClient(_EmptySessionStore());
    final requests = <RequestOptions>[];
    apiClient.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          if (options.method == 'PUT') {
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                statusCode: 200,
                data: _detailJson(title: '수정 글', content: '수정 내용'),
              ),
            );
          } else {
            handler.resolve(
              Response<void>(requestOptions: options, statusCode: 200),
            );
          }
        },
      ),
    );
    final repository = TeamPostRepository(apiClient);

    final updated = await repository.updatePost(
      3,
      7,
      const TeamPostInput(title: '수정 글', content: '수정 내용'),
    );
    await repository.deletePost(3, 7);

    expect(requests[0].method, 'PUT');
    expect(requests[0].path, '/api/teams/3/posts/7');
    expect(requests[0].data, {'title': '수정 글', 'content': '수정 내용'});
    expect(requests[1].method, 'DELETE');
    expect(requests[1].path, '/api/teams/3/posts/7');
    expect(updated.title, '수정 글');
  });

  test('팀 게시글 댓글 목록을 조회한다', () async {
    final apiClient = ApiClient(_EmptySessionStore());
    RequestOptions? request;
    apiClient.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          request = options;
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 200,
              data: [
                _commentJson(2, '2026-07-16T12:10:00'),
                _commentJson(1, '2026-07-16T12:00:00'),
              ],
            ),
          );
        },
      ),
    );

    final comments = await TeamPostRepository(apiClient).fetchComments(3, 7);

    expect(request?.method, 'GET');
    expect(request?.path, '/api/teams/3/posts/7/comments');
    expect(comments.map((comment) => comment.commentId), [1, 2]);
  });

  test('팀 게시글 댓글 작성 요청을 전송한다', () async {
    final apiClient = ApiClient(_EmptySessionStore());
    RequestOptions? request;
    apiClient.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          request = options;
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 201,
              data: _commentJson(3, '2026-07-16T12:20:00'),
            ),
          );
        },
      ),
    );

    final comment = await TeamPostRepository(
      apiClient,
    ).createComment(3, 7, '참석합니다.');

    expect(request?.method, 'POST');
    expect(request?.path, '/api/teams/3/posts/7/comments');
    expect(request?.data, {'content': '참석합니다.'});
    expect(comment.commentId, 3);
  });
}

Map<String, Object?> _summaryJson(int id, String createdAt) => {
  'postId': id,
  'teamId': 3,
  'authorMemberId': 2,
  'title': '게시글 $id',
  'authorUsername': 'test',
  'createdAt': createdAt,
};

Map<String, Object?> _detailJson({
  String title = '새 글',
  String content = '새 내용',
}) => {
  'postId': 7,
  'teamId': 3,
  'authorMemberId': 2,
  'title': title,
  'content': content,
  'authorUsername': 'test',
  'createdAt': '2026-07-16T12:00:00',
  'updatedAt': '2026-07-16T12:00:00',
};

Map<String, Object?> _commentJson(int id, String createdAt) => {
  'commentId': id,
  'postId': 7,
  'authorMemberId': 2,
  'authorUsername': 'test',
  'content': '참석합니다.',
  'createdAt': createdAt,
  'updatedAt': createdAt,
};

class _EmptySessionStore implements SessionStore {
  @override
  Future<void> clear() async {}

  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> save(AuthSession session) async {}
}
