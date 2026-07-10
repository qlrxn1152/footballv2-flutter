import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/features/teams/data/team_models.dart';

void main() {
  test('팀 상세 응답을 변환한다', () {
    final team = TeamDetail.fromJson({
      'teamId': 1,
      'teamName': 'FootMasters',
      'teamRating': 1600,
      'leaderMemberId': 10,
      'leaderUsername': 'captain',
      'memberCount': 4,
      'createdAt': '2026-07-10T10:30:00',
    });

    expect(team.teamName, 'FootMasters');
    expect(team.teamRating, 1600);
    expect(team.memberCount, 4);
    expect(team.createdAt, DateTime(2026, 7, 10, 10, 30));
  });

  test('팀장의 역할을 구분한다', () {
    final member = TeamMember.fromJson({
      'teamMemberId': 5,
      'teamId': 1,
      'teamName': 'FootMasters',
      'memberId': 10,
      'username': 'captain',
      'memberRating': 1600,
      'teamRole': 'LEADER',
      'joinedAt': '2026-07-10T10:30:00',
    });

    expect(member.isLeader, isTrue);
  });

  test('현재 백엔드의 가입 신청 상태값을 변환한다', () {
    final request = TeamJoinRequest.fromJson({
      'teamJoinRequestId': 8,
      'teamId': 1,
      'teamName': 'FootMasters',
      'memberId': 11,
      'username': 'player',
      'status': 'ACCEPTED',
      'createdAt': '2026-07-10T10:30:00',
    });

    expect(request.status, 'ACCEPTED');
  });

  test('팀 목록의 문자형 숫자와 이전 필드명도 변환한다', () {
    final team = TeamSummary.fromJson({
      'id': '2',
      'name': 'LegacyTeam',
      'rating': '1510',
      'leaderId': '20',
      'leaderName': 'captain',
      'teamMemberCount': '3',
      'createdAt': '2026-07-10T10:30:00',
    });

    expect(team.teamId, 2);
    expect(team.teamName, 'LegacyTeam');
    expect(team.teamRating, 1510);
    expect(team.leaderMemberId, 20);
    expect(team.memberCount, 3);
  });

  test('팀 목록의 부가 필드가 null이어도 핵심 정보는 표시한다', () {
    final team = TeamSummary.fromJson({
      'teamId': 3,
      'teamName': 'NewTeam',
      'teamRating': null,
      'leaderMemberId': null,
      'leaderUsername': null,
      'memberCount': null,
      'createdAt': null,
    });

    expect(team.teamRating, 0);
    expect(team.leaderUsername, '리더 정보 없음');
    expect(team.memberCount, 0);
  });

  test('실제 팀 목록 응답 두 건을 모두 변환한다', () {
    final response = [
      {
        'teamId': 3,
        'teamName': 'teamA',
        'teamRating': 1500,
        'leaderMemberId': 2,
        'leaderUsername': 'test',
        'memberCount': 1,
        'createdAt': '2026-07-09T00:00:00',
      },
      {
        'teamId': 4,
        'teamName': 'tttttt11',
        'teamRating': 1500,
        'leaderMemberId': 6,
        'leaderUsername': 'asdf',
        'memberCount': 1,
        'createdAt': '2026-07-09T21:01:54.281688',
      },
    ];

    final teams = response.map(TeamSummary.fromJson).toList();

    expect(teams, hasLength(2));
    expect(teams.first.teamName, 'teamA');
    expect(teams.last.leaderUsername, 'asdf');
  });

  test('팀장 위임 응답을 변환한다', () {
    final result = TeamLeaderTransferResult.fromJson({
      'teamId': 3,
      'teamName': 'teamA',
      'oldLeaderMemberId': 2,
      'oldLeaderUsername': 'test',
      'newLeaderMemberId': 7,
      'newLeaderUsername': 'newLeader',
    });

    expect(result.teamId, 3);
    expect(result.oldLeaderUsername, 'test');
    expect(result.newLeaderMemberId, 7);
    expect(result.newLeaderUsername, 'newLeader');
  });
}
