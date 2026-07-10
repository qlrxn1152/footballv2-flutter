import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'team_models.dart';

class TeamRepository {
  const TeamRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<TeamSummary>> fetchTeams() {
    return runApi(() async {
      final response = await _apiClient.dio.get<Object?>('/api/teams');
      final data = response.data;
      if (data is! List) {
        throw const ApiException('팀 목록 응답 형식이 올바르지 않습니다.');
      }
      return data
          .map((item) => TeamSummary.fromJson(jsonMap(item)))
          .toList(growable: false);
    });
  }

  Future<TeamDetail> fetchTeamDetail(int teamId) {
    return runApi(() async {
      final response = await _apiClient.dio.get<Object?>(
        '/api/teams/$teamId',
      );
      return TeamDetail.fromJson(jsonMap(response.data));
    });
  }

  Future<List<TeamMember>> fetchTeamMembers(int teamId) {
    return runApi(() async {
      final response = await _apiClient.dio.get<Object?>(
        '/api/teams/$teamId/members',
      );
      final data = response.data;
      if (data is! List) {
        throw const ApiException('팀원 목록 응답 형식이 올바르지 않습니다.');
      }
      return data
          .map((item) => TeamMember.fromJson(jsonMap(item)))
          .toList(growable: false);
    });
  }

  Future<int> createTeam(String teamName) {
    return runApi(() async {
      final response = await _apiClient.dio.post<Object?>(
        '/api/teams',
        data: {'teamName': teamName},
      );
      return (jsonMap(response.data)['teamId'] as num).toInt();
    });
  }

  Future<void> requestJoin(int teamId) {
    return runApi(() async {
      await _apiClient.dio.post<Object?>(
        '/api/teams/$teamId/join-requests',
      );
    });
  }

  Future<List<TeamJoinRequest>> fetchJoinRequests({
    required int teamId,
    required String status,
  }) {
    return runApi(() async {
      final response = await _apiClient.dio.get<Object?>(
        '/api/teams/$teamId/join-requests',
        queryParameters: {'status': status},
      );
      final data = response.data;
      if (data is! List) {
        throw const ApiException('가입 신청 목록 응답 형식이 올바르지 않습니다.');
      }
      return data
          .map((item) => TeamJoinRequest.fromJson(jsonMap(item)))
          .toList(growable: false);
    });
  }

  Future<void> decideJoinRequest({
    required int teamId,
    required int requestId,
    required bool accept,
  }) {
    final decision = accept ? 'accept' : 'reject';
    return runApi(() async {
      await _apiClient.dio.post<Object?>(
        '/api/teams/$teamId/join-requests/$requestId/$decision',
      );
    });
  }
}

final teamRepositoryProvider = Provider<TeamRepository>(
  (ref) => TeamRepository(ref.watch(apiClientProvider)),
);

final teamsProvider = FutureProvider<List<TeamSummary>>(
  (ref) => ref.watch(teamRepositoryProvider).fetchTeams(),
);

final teamDetailProvider = FutureProvider.family<TeamDetail, int>(
  (ref, teamId) => ref.watch(teamRepositoryProvider).fetchTeamDetail(teamId),
);

final teamMembersProvider = FutureProvider.family<List<TeamMember>, int>(
  (ref, teamId) => ref.watch(teamRepositoryProvider).fetchTeamMembers(teamId),
);

typedef JoinRequestQuery = ({int teamId, String status});

final joinRequestsProvider =
    FutureProvider.family<List<TeamJoinRequest>, JoinRequestQuery>(
      (ref, query) => ref
          .watch(teamRepositoryProvider)
          .fetchJoinRequests(teamId: query.teamId, status: query.status),
    );
