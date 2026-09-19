import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'footmatch_directory.dart';
import 'footmatch_match.dart';

final footmatchRepositoryProvider = Provider<FootmatchRepository>(
  (ref) => FootmatchRepository(ref.watch(apiClientProvider).dio),
);

class FootmatchRepository {
  FootmatchRepository(this.dio);
  final Dio dio;

  Future<Map<String, dynamic>> _request(
    String method,
    String path, [
    Map<String, dynamic>? data,
  ]) =>
      runApi(() async {
        final response = await dio.request<Object?>(
          path,
          data: data,
          options: Options(method: method),
        );
        if (response.data == null || response.data == '') return {};
        return jsonMap(response.data);
      });

  Future<Map<String, dynamic>> me() => _request('GET', '/api/members/me');

  Future<List<FootmatchMemberListItem>> memberList() async {
    final response = await _request('GET', '/api/members/list');
    final items = response['members'];
    if (items is! List) {
      throw const ApiException('멤버 목록 응답 형식이 올바르지 않습니다.');
    }
    return items
        .map((item) => FootmatchMemberListItem.fromJson(jsonMap(item)))
        .toList(growable: false);
  }

  Future<List<FootmatchTeamListItem>> teamList() async {
    final response = await _request('GET', '/api/teams/list');
    final items = response['teams'];
    if (items is! List) {
      throw const ApiException('팀 목록 응답 형식이 올바르지 않습니다.');
    }
    return items
        .map((item) => FootmatchTeamListItem.fromJson(jsonMap(item)))
        .toList(growable: false);
  }
  Future<Map<String, dynamic>> team(int id) =>
      _request('GET', '/api/teams/$id');
  Future<Map<String, dynamic>> members(int id) =>
      _request('GET', '/api/teams/$id/members');
  Future<Map<String, dynamic>> createTeam(String name) =>
      _request('POST', '/api/teams', {'teamName': name});
  Future<Map<String, dynamic>> renameTeam(int id, String name) =>
      _request('PATCH', '/api/teams/$id/name', {'teamName': name});
  Future<Map<String, dynamic>> transferLeader(int id, int memberId) =>
      _request('PATCH', '/api/teams/$id/leader', {'targetMemberId': memberId});
  Future<Map<String, dynamic>> leave(int id) =>
      _request('DELETE', '/api/teams/$id/members/me');
  Future<Map<String, dynamic>> kick(int id, int memberId) =>
      _request('DELETE', '/api/teams/$id/members/$memberId');
  Future<Map<String, dynamic>> join(int id) =>
      _request('POST', '/api/teams/$id/join-request');
  Future<Map<String, dynamic>> requests(int id) =>
      _request('GET', '/api/teams/$id/join-requests');
  Future<Map<String, dynamic>> acceptJoin(int id, int requestId) =>
      _request('POST', '/api/teams/$id/join-request/$requestId/accept');
  Future<Map<String, dynamic>> rejectJoin(int id, int requestId) =>
      _request('POST', '/api/teams/$id/join-request/$requestId/reject');
  Future<Map<String, dynamic>> cancelJoin(int id, int requestId) =>
      _request('POST', '/api/teams/$id/join-request/$requestId/cancel');

  Future<Map<String, dynamic>> createMatch(int teamId, DateTime playedAt) =>
      _matchMutation(
        '/api/team-matches/$teamId/matches',
        {'playedAt': playedAt.toIso8601String()},
      );

  Future<Map<String, dynamic>> requestMatch(int matchId) =>
      _matchMutation('/api/team-matches/$matchId/accept-requests');

  // Keep registration/participation working while Railway is on the old API.
  // Only a missing route permits a retry; never retry auth, business, or network errors.
  Future<Map<String, dynamic>> _matchMutation(
    String path, [
    Map<String, dynamic>? data,
  ]) async {
    try {
      return await _request('POST', path, data);
    } on ApiException catch (error) {
      if (error.statusCode != 404 || error.code != null) rethrow;
      try {
        return await _request(
          'POST',
          path.replaceFirst('/api/team-matches/', '/api/team-match/'),
          data,
        );
      } on ApiException {
        throw error;
      }
    }
  }

  Future<List<FootmatchMatch>> matches(
    FootmatchMatchStatus status, {
    int? teamId,
  }) async {
    final path = teamId == null
        ? '/api/team-matches/${status.name}'
        : '/api/teams/$teamId/matches/${status.name}';
    final response = await _request('GET', path);
    final items = response['${status.name}Matches'];
    if (items is! List) {
      throw const ApiException('경기 목록 응답 형식이 올바르지 않습니다.');
    }
    return items
        .map((item) => FootmatchMatch.fromJson(jsonMap(item), status))
        .toList(growable: false);
  }

  Future<List<FootmatchMatchAcceptRequest>> matchAcceptRequests(
    int teamId,
  ) async {
    final response = await _request(
      'GET',
      '/api/team-matches/$teamId/request/pendings',
    );
    final items = response['requests'];
    if (items is! List) {
      throw const ApiException('경기 참가 신청 응답 형식이 올바르지 않습니다.');
    }
    return items
        .map((item) => FootmatchMatchAcceptRequest.fromJson(jsonMap(item)))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> acceptMatch(int matchId, int requestId) =>
      _request(
        'POST',
        '/api/team-matches/$matchId/accept-requests/$requestId',
      );

  Future<FootmatchMatchResult> createMatchResult({
    required int matchId,
    required int homeScore,
    required int awayScore,
  }) async {
    final response = await _request(
      'POST',
      '/api/team-matches/$matchId/result/score',
      {
        'homeScore': homeScore,
        'awayScore': awayScore,
      },
    );
    return FootmatchMatchResult.fromJson(response);
  }
}
