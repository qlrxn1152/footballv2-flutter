import 'package:flutter/foundation.dart';
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
      final rows = _teamRows(response.data);
      final teams = <TeamSummary>[];

      for (var index = 0; index < rows.length; index++) {
        try {
          teams.add(TeamSummary.fromJson(jsonMap(rows[index])));
        } catch (_) {
          // 일부 오래된 데이터가 현재 DTO와 달라도 정상 팀은 계속 표시합니다.
          continue;
        }
      }

      if (rows.isNotEmpty && teams.isEmpty) {
        throw const ApiException(
          '팀 데이터의 teamId 또는 teamName을 읽지 못했습니다. '
          '백엔드 응답 필드를 확인하세요.',
        );
      }
      if (kDebugMode) {
        debugPrint(
          '[FootballV2] GET /api/teams '
          'status=${response.statusCode}, received=${rows.length}, '
          'parsed=${teams.length}',
        );
      }
      return List.unmodifiable(teams);
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

  Future<TeamLeaderTransferResult> transferLeader({
    required int teamId,
    required int newLeaderMemberId,
  }) {
    return runApi(() async {
      final response = await _apiClient.dio.patch<Object?>(
        '/api/teams/$teamId/leader',
        data: {'newLeaderMemberId': newLeaderMemberId},
      );
      return TeamLeaderTransferResult.fromJson(jsonMap(response.data));
    });
  }

  Future<TeamNameUpdateResult> updateTeamName({
    required int teamId,
    required String teamName,
  }) {
    return runApi(() async {
      final response = await _apiClient.dio.patch<Object?>(
        '/api/teams/$teamId/name',
        data: {'teamName': teamName},
      );
      if (response.statusCode == 204) {
        throw const ApiException('현재 팀 이름과 다른 이름을 입력하세요.');
      }
      return TeamNameUpdateResult.fromJson(jsonMap(response.data));
    });
  }

  Future<TeamDisbandResult> disbandTeam(int teamId) {
    return runApi(() async {
      final response = await _apiClient.dio.delete<Object?>(
        '/api/teams/$teamId',
      );
      if (response.statusCode == 204) {
        throw const ApiException('팀장만 남은 팀만 해체할 수 있습니다.');
      }
      return TeamDisbandResult.fromJson(jsonMap(response.data));
    });
  }
}

List<dynamic> _teamRows(Object? data) {
  Object? current = data;
  for (var depth = 0; depth < 3; depth++) {
    if (current is List) return current;
    if (current is Map) {
      Object? next;
      for (final key in const ['content', 'teams', 'data']) {
        if (current[key] != null) {
          next = current[key];
          break;
        }
      }
      current = next;
      continue;
    }
    break;
  }
  throw const ApiException('팀 목록 응답이 배열 형식이 아닙니다.');
}

final teamRepositoryProvider = Provider<TeamRepository>(
  (ref) => TeamRepository(ref.watch(apiClientProvider)),
);

final teamsProvider = FutureProvider<List<TeamSummary>>(
  (ref) => ref.watch(teamRepositoryProvider).fetchTeams(),
);

final teamDetailProvider = FutureProvider.autoDispose.family<TeamDetail, int>(
  (ref, teamId) => ref.watch(teamRepositoryProvider).fetchTeamDetail(teamId),
);

final teamMembersProvider =
    FutureProvider.autoDispose.family<List<TeamMember>, int>(
      (ref, teamId) =>
          ref.watch(teamRepositoryProvider).fetchTeamMembers(teamId),
    );

typedef JoinRequestQuery = ({int teamId, String status});

final joinRequestsProvider = FutureProvider.autoDispose
    .family<List<TeamJoinRequest>, JoinRequestQuery>(
      (ref, query) => ref
          .watch(teamRepositoryProvider)
          .fetchJoinRequests(teamId: query.teamId, status: query.status),
    );
