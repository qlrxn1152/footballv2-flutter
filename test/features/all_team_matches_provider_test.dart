import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/features/matches/data/team_match.dart';
import 'package:footballv2_flutter/features/matches/data/team_match_repository.dart';

void main() {
  TeamMatchSummary match({
    required int id,
    required String status,
    required String createdAt,
  }) {
    return TeamMatchSummary.fromJson({
      'teamMatchId': id,
      'homeTeamId': id,
      'homeTeamName': 'team$id',
      'homeTeamRating': 1500,
      'awayTeamId': status == 'PENDING' ? null : id + 10,
      'awayTeamName': status == 'PENDING' ? null : 'away$id',
      'awayTeamRating': status == 'PENDING' ? null : 1500,
      'status': status,
      'createdAt': createdAt,
    });
  }

  test('상태별 매치를 합쳐 최신순으로 정렬한다', () async {
    final pending = match(
      id: 1,
      status: 'PENDING',
      createdAt: '2026-07-12T10:00:00',
    );
    final matched = match(
      id: 2,
      status: 'MATCHED',
      createdAt: '2026-07-12T12:00:00',
    );
    final completed = match(
      id: 3,
      status: 'COMPLETED',
      createdAt: '2026-07-12T11:00:00',
    );
    final container = ProviderContainer(
      overrides: [
        teamMatchesProvider(
          'PENDING',
        ).overrideWith((ref) async => [pending]),
        teamMatchesProvider(
          'MATCHED',
        ).overrideWith((ref) async => [matched]),
        teamMatchesProvider(
          'COMPLETED',
        ).overrideWith((ref) async => [completed]),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(allTeamMatchesProvider.future);

    expect(result.map((item) => item.teamMatchId), [2, 3, 1]);
  });

  test('원정 팀으로 참여 중인 MATCHED 매치도 활성 매치로 찾는다', () async {
    final matched = TeamMatchSummary.fromJson({
      'teamMatchId': 7,
      'homeTeamId': 3,
      'homeTeamName': 'teamA',
      'homeTeamRating': 1500,
      'awayTeamId': 4,
      'awayTeamName': 'teamB',
      'awayTeamRating': 1510,
      'status': 'MATCHED',
      'createdAt': '2026-07-13T10:00:00',
    });
    final container = ProviderContainer(
      overrides: [
        teamMatchesProvider(
          'PENDING',
        ).overrideWith((ref) async => const <TeamMatchSummary>[]),
        teamMatchesProvider(
          'MATCHED',
        ).overrideWith((ref) async => [matched]),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(activeTeamMatchProvider(4).future);

    expect(result?.teamMatchId, 7);
    expect(result?.awayTeamId, 4);
  });
}
