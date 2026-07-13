import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/features/members/data/member_detail.dart';

void main() {
  test('팀이 있는 멤버 상세 응답을 변환한다', () {
    final member = MemberDetail.fromJson({
      'memberId': 1,
      'username': 'captain',
      'memberRating': 1700,
      'totalGoalCount': 12,
      'teamId': 3,
      'teamName': 'FootMasters',
      'teamRole': 'LEADER',
      'joinedAt': '2026-07-09T10:30:00',
      'createdAt': '2026-07-08T09:00:00',
    });

    expect(member.memberId, 1);
    expect(member.memberRating, 1700);
    expect(member.totalGoalCount, 12);
    expect(member.hasTeam, isTrue);
    expect(member.isLeader, isTrue);
    expect(member.teamName, 'FootMasters');
    expect(member.joinedAt, DateTime(2026, 7, 9, 10, 30));
  });

  test('팀이 없는 멤버 상세 응답의 팀 정보는 null이다', () {
    final member = MemberDetail.fromJson({
      'memberId': 2,
      'username': 'freeAgent',
      'memberRating': 1500,
      'totalGoalCount': 0,
      'teamId': null,
      'teamName': null,
      'teamRole': null,
      'joinedAt': null,
      'createdAt': '2026-07-08T09:00:00',
    });

    expect(member.hasTeam, isFalse);
    expect(member.totalGoalCount, 0);
    expect(member.isLeader, isFalse);
    expect(member.teamId, isNull);
    expect(member.teamName, isNull);
    expect(member.joinedAt, isNull);
  });
}
