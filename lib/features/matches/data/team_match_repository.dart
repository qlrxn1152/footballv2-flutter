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
}

final teamMatchRepositoryProvider = Provider<TeamMatchRepository>(
  (ref) => TeamMatchRepository(ref.watch(apiClientProvider)),
);
