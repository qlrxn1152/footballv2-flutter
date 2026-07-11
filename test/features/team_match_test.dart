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
}
