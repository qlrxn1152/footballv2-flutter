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
    final match = TeamMatchSummary.fromJson({
      'teamMatchId': 21,
      'homeTeamId': 3,
      'homeTeamName': 'teamA',
      'homeTeamRating': 1500,
      'awayTeamId': null,
      'awayTeamName': null,
      'awayTeamRating': null,
      'status': 'PENDING',
      'createdAt': '2026-07-11T14:30:00',
    });

    expect(match.teamMatchId, 21);
    expect(match.homeTeamName, 'teamA');
    expect(match.awayTeamId, isNull);
    expect(match.status, 'PENDING');
    expect(match.isPending, isTrue);
    expect(match.createdAt, DateTime(2026, 7, 11, 14, 30));
  });

  test('MATCHED 매치 목록 응답을 변환한다', () {
    final match = TeamMatchSummary.fromJson({
      'teamMatchId': 22,
      'homeTeamId': 3,
      'homeTeamName': 'teamA',
      'homeTeamRating': 1500,
      'awayTeamId': 4,
      'awayTeamName': 'teamB',
      'awayTeamRating': 1510,
      'status': 'MATCHED',
      'createdAt': '2026-07-11T15:00:00',
    });

    expect(match.awayTeamId, 4);
    expect(match.awayTeamName, 'teamB');
    expect(match.awayTeamRating, 1510);
    expect(match.isMatched, isTrue);
    expect(match.includesTeam(4), isTrue);
  });

  test('매치 수락 응답을 변환한다', () {
    final result = TeamMatchAcceptResult.fromJson({
      'teamMatchId': 22,
      'homeTeamId': 3,
      'homeTeamName': 'teamA',
      'homeTeamRating': 1500,
      'awayTeamId': 4,
      'awayTeamName': 'teamB',
      'awayTeamRating': 1510,
      'status': 'MATCHED',
    });

    expect(result.teamMatchId, 22);
    expect(result.homeTeamName, 'teamA');
    expect(result.awayTeamName, 'teamB');
    expect(result.status, 'MATCHED');
  });

  test('매치 결과 등록 응답을 변환한다', () {
    final result = TeamMatchResult.fromJson({
      'teamMatchId': 22,
      'homeTeamId': 3,
      'homeTeamName': 'teamA',
      'homeScore': 3,
      'awayTeamId': 4,
      'awayTeamName': 'teamB',
      'awayScore': 1,
      'winnerTeamId': 3,
      'winnerTeamName': 'teamA',
      'status': 'COMPLETED',
    });

    expect(result.homeScore, 3);
    expect(result.awayScore, 1);
    expect(result.winnerTeamName, 'teamA');
    expect(result.isDraw, isFalse);
    expect(result.isCompleted, isTrue);
  });

  test('무승부 결과는 승리 팀이 없다', () {
    final result = TeamMatchResult.fromJson({
      'teamMatchId': 22,
      'homeTeamId': 3,
      'homeTeamName': 'teamA',
      'homeScore': 2,
      'awayTeamId': 4,
      'awayTeamName': 'teamB',
      'awayScore': 2,
      'winnerTeamId': null,
      'winnerTeamName': null,
      'status': 'COMPLETED',
    });

    expect(result.isDraw, isTrue);
    expect(result.winnerTeamName, isNull);
  });
}
