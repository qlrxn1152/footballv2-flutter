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

  Future<List<PendingTeamMatch>> fetchPendingMatches() {
    return runApi(() async {
      final response = await _apiClient.dio.get<Object?>(
        '/api/team-matches/pending',
      );
      final data = response.data;
      if (data is! List) {
        throw const ApiException('대기 매치 목록 응답 형식이 올바르지 않습니다.');
      }
      return data
          .map((item) => PendingTeamMatch.fromJson(jsonMap(item)))
          .toList(growable: false);
    });
  }
}

final teamMatchRepositoryProvider = Provider<TeamMatchRepository>(
  (ref) => TeamMatchRepository(ref.watch(apiClientProvider)),
);

final pendingTeamMatchesProvider =
    FutureProvider.autoDispose<List<PendingTeamMatch>>(
      (ref) => ref.watch(teamMatchRepositoryProvider).fetchPendingMatches(),
    );
