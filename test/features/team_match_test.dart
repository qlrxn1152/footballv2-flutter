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
      'playedAt': '2026-07-20T18:30:00',
      'createdAt': '2026-07-12T10:00:00',
    });

    expect(result.teamMatchId, 12);
    expect(result.homeTeamId, 3);
    expect(result.homeTeamName, 'teamA');
    expect(result.homeTeamRating, 1500);
    expect(result.isPending, isTrue);
    expect(result.playedAt, DateTime(2026, 7, 20, 18, 30));
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
      'playedAt': '2026-07-20T18:30:00',
    });

    expect(match.teamMatchId, 21);
    expect(match.homeTeamName, 'teamA');
    expect(match.awayTeamId, isNull);
    expect(match.status, 'PENDING');
    expect(match.isPending, isTrue);
    expect(match.createdAt, DateTime(2026, 7, 11, 14, 30));
    expect(match.playedAt, DateTime(2026, 7, 20, 18, 30));
  });

  test('완료된 매치 상세 응답을 변환한다', () {
    final detail = TeamMatchDetail.fromJson({
      'teamMatchId': 23,
      'homeTeamId': 3,
      'homeTeamName': 'teamA',
      'homeTeamRating': 1512,
      'awayTeamId': 4,
      'awayTeamName': 'teamB',
      'awayTeamRating': 1488,
      'status': 'COMPLETED',
      'createdAt': '2026-07-12T10:00:00',
      'playedAt': '2026-07-20T18:30:00',
      'homeScore': 3,
      'awayScore': 1,
      'winnerTeamId': 3,
      'winnerTeamName': 'teamA',
    });

    expect(detail.teamMatchId, 23);
    expect(detail.playedAt, DateTime(2026, 7, 20, 18, 30));
    expect(detail.hasResult, isTrue);
    expect(detail.isCompleted, isTrue);
    expect(detail.winnerTeamName, 'teamA');
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

  test('COMPLETED 매치 목록의 점수와 승자를 변환한다', () {
    final match = TeamMatchSummary.fromJson({
      'teamMatchId': 23,
      'homeTeamId': 3,
      'homeTeamName': 'teamA',
      'homeTeamRating': 1500,
      'homeScore': 4,
      'awayTeamId': 4,
      'awayTeamName': 'teamB',
      'awayTeamRating': 1510,
      'awayScore': 2,
      'winnerTeamId': 3,
      'winnerTeamName': 'teamA',
      'status': 'COMPLETED',
      'createdAt': '2026-07-11T16:00:00',
    });

    expect(match.homeScore, 4);
    expect(match.awayScore, 2);
    expect(match.winnerTeamId, 3);
    expect(match.winnerTeamName, 'teamA');
    expect(match.hasResult, isTrue);
    expect(match.isDraw, isFalse);
  });

  test('COMPLETED 무승부 매치는 승자가 없다', () {
    final match = TeamMatchSummary.fromJson({
      'teamMatchId': 24,
      'homeTeamId': 3,
      'homeTeamName': 'teamA',
      'homeTeamRating': 1500,
      'homeScore': 2,
      'awayTeamId': 4,
      'awayTeamName': 'teamB',
      'awayTeamRating': 1510,
      'awayScore': 2,
      'winnerTeamId': null,
      'winnerTeamName': null,
      'status': 'COMPLETED',
      'createdAt': '2026-07-11T17:00:00',
    });

    expect(match.hasResult, isTrue);
    expect(match.isDraw, isTrue);
    expect(match.winnerTeamName, isNull);
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
      'goals': [
        {
          'teamId': 3,
          'teamMatchId': 22,
          'scorerMemberId': 2,
          'scorerUsername': 'test',
          'goalCount': 2,
        },
        {
          'teamId': 3,
          'teamMatchId': 22,
          'scorerMemberId': 7,
          'scorerUsername': 'playerA',
          'goalCount': 1,
        },
        {
          'teamId': 4,
          'teamMatchId': 22,
          'scorerMemberId': 6,
          'scorerUsername': 'away',
          'goalCount': 1,
        },
      ],
    });

    expect(result.homeScore, 3);
    expect(result.awayScore, 1);
    expect(result.winnerTeamName, 'teamA');
    expect(result.isDraw, isFalse);
    expect(result.isCompleted, isTrue);
    expect(result.goals, hasLength(3));
    expect(result.goals.first.scorerUsername, 'test');
    expect(result.goals.first.goalCount, 2);
  });

  test('득점자 입력을 API 요청 형식으로 변환한다', () {
    const goal = TeamMatchGoalInput(
      teamId: 3,
      scorerMemberId: 2,
      goalCount: 2,
    );

    expect(goal.toJson(), {
      'teamId': 3,
      'scorerMemberId': 2,
      'goalCount': 2,
    });
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
