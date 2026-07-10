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
}
