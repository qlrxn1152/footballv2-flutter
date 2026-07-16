import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'team_post.dart';
import 'team_post_comment.dart';

class TeamPostRepository {
  const TeamPostRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<TeamPostSummary>> fetchPosts(int teamId) {
    return runApi(() async {
      final response = await _apiClient.dio.get<Object?>(
        '/api/teams/$teamId/posts',
      );
      final data = response.data;
      if (data is! List) {
        throw const ApiException('팀 게시글 목록 응답 형식이 올바르지 않습니다.');
      }
      final posts = data
          .map((item) => TeamPostSummary.fromJson(jsonMap(item)))
          .toList(growable: false);
      return posts.toList()
        ..sort((a, b) {
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
    });
  }

  Future<TeamPostDetail> fetchPost(int teamId, int postId) {
    return runApi(() async {
      final response = await _apiClient.dio.get<Object?>(
        '/api/teams/$teamId/posts/$postId',
      );
      return TeamPostDetail.fromJson(jsonMap(response.data));
    });
  }

  Future<TeamPostDetail> createPost(int teamId, TeamPostInput input) {
    return runApi(() async {
      final response = await _apiClient.dio.post<Object?>(
        '/api/teams/$teamId/posts',
        data: input.toJson(),
      );
      return TeamPostDetail.fromJson(jsonMap(response.data));
    });
  }

  Future<TeamPostDetail> updatePost(
    int teamId,
    int postId,
    TeamPostInput input,
  ) {
    return runApi(() async {
      final response = await _apiClient.dio.put<Object?>(
        '/api/teams/$teamId/posts/$postId',
        data: input.toJson(),
      );
      return TeamPostDetail.fromJson(jsonMap(response.data));
    });
  }

  Future<void> deletePost(int teamId, int postId) {
    return runApi(() async {
      await _apiClient.dio.delete<void>(
        '/api/teams/$teamId/posts/$postId',
      );
    });
  }

  Future<List<TeamPostComment>> fetchComments(int teamId, int postId) {
    return runApi(() async {
      final response = await _apiClient.dio.get<Object?>(
        '/api/teams/$teamId/posts/$postId/comments',
      );
      final data = response.data;
      if (data is! List) {
        throw const ApiException('댓글 목록 응답 형식이 올바르지 않습니다.');
      }
      final comments = data
          .map((item) => TeamPostComment.fromJson(jsonMap(item)))
          .toList(growable: false);
      return comments.toList()
        ..sort((a, b) {
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return aDate.compareTo(bDate);
        });
    });
  }

  Future<TeamPostComment> createComment(
    int teamId,
    int postId,
    String content,
  ) {
    return runApi(() async {
      final response = await _apiClient.dio.post<Object?>(
        '/api/teams/$teamId/posts/$postId/comments',
        data: {'content': content},
      );
      return TeamPostComment.fromJson(jsonMap(response.data));
    });
  }

  Future<TeamPostComment> updateComment(
    int teamId,
    int postId,
    int commentId,
    String content,
  ) {
    return runApi(() async {
      final response = await _apiClient.dio.put<Object?>(
        '/api/teams/$teamId/posts/$postId/comments/$commentId',
        data: {'content': content},
      );
      return TeamPostComment.fromJson(jsonMap(response.data));
    });
  }

  Future<void> deleteComment(int teamId, int postId, int commentId) {
    return runApi(() async {
      await _apiClient.dio.delete<void>(
        '/api/teams/$teamId/posts/$postId/comments/$commentId',
      );
    });
  }
}

final teamPostRepositoryProvider = Provider<TeamPostRepository>(
  (ref) => TeamPostRepository(ref.watch(apiClientProvider)),
);

final teamPostsProvider = FutureProvider.autoDispose
    .family<List<TeamPostSummary>, int>(
      (ref, teamId) => ref.watch(teamPostRepositoryProvider).fetchPosts(teamId),
    );

typedef TeamPostQuery = ({int teamId, int postId});

final teamPostDetailProvider = FutureProvider.autoDispose
    .family<TeamPostDetail, TeamPostQuery>(
      (ref, query) => ref
          .watch(teamPostRepositoryProvider)
          .fetchPost(query.teamId, query.postId),
    );

final teamPostCommentsProvider = FutureProvider.autoDispose
    .family<List<TeamPostComment>, TeamPostQuery>(
      (ref, query) => ref
          .watch(teamPostRepositoryProvider)
          .fetchComments(query.teamId, query.postId),
    );
