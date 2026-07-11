import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/features/matches/data/team_match.dart';

void main() {
  test('매치 등록 응답을 변환한다', () {
    final result = TeamMatchCreateResult.fromJson({
      'teamMatchId': 12,
      'homeTeamId': 3,
      'homeTeamName': 'teamA',
      'homeTeamRating': 1500,
      'status': 'PENDING',
    });

    expect(result.teamMatchId, 12);
    expect(result.homeTeamId, 3);
    expect(result.homeTeamName, 'teamA');
    expect(result.homeTeamRating, 1500);
    expect(result.isPending, isTrue);
  });

  test('PENDING 매치 목록 응답을 변환한다', () {
    final match = PendingTeamMatch.fromJson({
      'teamMatchId': 21,
      'homeTeamId': 3,
      'homeTeamName': 'teamA',
      'homeTeamRating': 1500,
      'status': 'PENDING',
      'createdAt': '2026-07-11T14:30:00',
    });

    expect(match.teamMatchId, 21);
    expect(match.homeTeamName, 'teamA');
    expect(match.status, 'PENDING');
    expect(match.createdAt, DateTime(2026, 7, 11, 14, 30));
  });
}
