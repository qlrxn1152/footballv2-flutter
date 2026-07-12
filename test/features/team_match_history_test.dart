import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/features/matches/data/team_match_history.dart';

void main() {
  test('PENDING 팀 매치 기록을 변환한다', () {
    final match = TeamMatchHistory.fromJson({
      'teamMatchId': 31,
      'homeTeamId': 3,
      'homeTeamName': 'teamA',
      'awayTeamId': null,
      'awayTeamName': null,
      'status': 'PENDING',
      'createdAt': '2026-07-12T10:00:00',
      'homeScore': null,
      'awayScore': null,
      'winnerTeamId': null,
      'winnerTeamName': null,
    });

    expect(match.isPending, isTrue);
    expect(match.awayTeamId, isNull);
    expect(match.hasResult, isFalse);
    expect(match.includesTeam(3), isTrue);
  });

  test('COMPLETED 팀 매치 기록의 점수와 승자를 변환한다', () {
    final match = TeamMatchHistory.fromJson({
      'teamMatchId': 32,
      'homeTeamId': 3,
      'homeTeamName': 'teamA',
      'awayTeamId': 4,
      'awayTeamName': 'teamB',
      'status': 'COMPLETED',
      'createdAt': '2026-07-12T11:00:00',
      'homeScore': 3,
      'awayScore': 1,
      'winnerTeamId': 3,
      'winnerTeamName': 'teamA',
    });

    expect(match.isCompleted, isTrue);
    expect(match.homeScore, 3);
    expect(match.awayScore, 1);
    expect(match.winnerTeamName, 'teamA');
    expect(match.isDraw, isFalse);
    expect(match.includesTeam(4), isTrue);
  });

  test('동점인 완료 기록은 무승부다', () {
    final match = TeamMatchHistory.fromJson({
      'teamMatchId': 33,
      'homeTeamId': 3,
      'homeTeamName': 'teamA',
      'awayTeamId': 4,
      'awayTeamName': 'teamB',
      'status': 'COMPLETED',
      'createdAt': '2026-07-12T12:00:00',
      'homeScore': 2,
      'awayScore': 2,
      'winnerTeamId': null,
      'winnerTeamName': null,
    });

    expect(match.isDraw, isTrue);
    expect(match.winnerTeamName, isNull);
  });
}
