import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

final footmatchRepositoryProvider = Provider<FootmatchRepository>(
  (ref) => FootmatchRepository(ref.watch(apiClientProvider).dio),
);

class FootmatchRepository {
  FootmatchRepository(this.dio);
  final Dio dio;

  Future<Map<String, dynamic>> _request(String method, String path,
      [Map<String, dynamic>? data]) => runApi(() async {
    final response = await dio.request<Object?>(path,
        data: data, options: Options(method: method));
    if (response.data == null || response.data == '') return {};
    return jsonMap(response.data);
  });

  Future<Map<String, dynamic>> me() => _request('GET', '/api/members/me');
  Future<Map<String, dynamic>> team(int id) => _request('GET', '/api/teams/$id');
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
      _request('POST', '/api/team-match/$teamId/matches',
          {'playedAt': playedAt.toIso8601String()});
  Future<Map<String, dynamic>> requestMatch(int matchId) =>
      _request('POST', '/api/team-match/$matchId/accept-requests');
}
