import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'team_match.dart';

class TeamMatchRepository {
  const TeamMatchRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<TeamMatchCreateResult> createMatch(int teamId) {
    return runApi(() async {
      final response = await _apiClient.dio.post<Object?>(
        '/api/teams/$teamId/matches',
      );
      return TeamMatchCreateResult.fromJson(jsonMap(response.data));
    });
  }

  Future<List<TeamMatchSummary>> fetchMatches(String status) {
    return runApi(() async {
      final response = await _apiClient.dio.get<Object?>(
        '/api/team-matches',
        queryParameters: {'status': status},
      );
      final data = response.data;
      if (data is! List) {
        throw const ApiException('매치 목록 응답 형식이 올바르지 않습니다.');
      }
      return data
          .map((item) => TeamMatchSummary.fromJson(jsonMap(item)))
          .toList(growable: false);
    });
  }

  Future<TeamMatchAcceptResult> acceptMatch(int teamMatchId) {
    return runApi(() async {
      final response = await _apiClient.dio.patch<Object?>(
        '/api/team-matches/$teamMatchId/accept',
      );
      return TeamMatchAcceptResult.fromJson(jsonMap(response.data));
    });
  }

  Future<TeamMatchResult> registerResult({
    required int teamMatchId,
    required int homeScore,
    required int awayScore,
  }) {
    return runApi(() async {
      final response = await _apiClient.dio.post<Object?>(
        '/api/team-matches/$teamMatchId/result',
        data: {'homeScore': homeScore, 'awayScore': awayScore},
      );
      return TeamMatchResult.fromJson(jsonMap(response.data));
    });
  }
}

final teamMatchRepositoryProvider = Provider<TeamMatchRepository>(
  (ref) => TeamMatchRepository(ref.watch(apiClientProvider)),
);

final teamMatchesProvider = FutureProvider.autoDispose
    .family<List<TeamMatchSummary>, String>(
      (ref, status) =>
          ref.watch(teamMatchRepositoryProvider).fetchMatches(status),
    );
