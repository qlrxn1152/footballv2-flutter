import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/features/members/data/member_account.dart';

void main() {
  test('마이페이지 응답에서 팀 소속과 역할을 변환한다', () {
    final member = MemberMe.fromJson({
      'memberId': 10,
      'username': 'player',
      'memberRating': 1500,
      'teamId': 3,
      'teamName': 'FootMasters',
      'teamRole': 'MEMBER',
      'joinedAt': '2026-07-10T10:30:00',
      'createdAt': '2026-07-01T09:00:00',
    });

    expect(member.hasTeam, isTrue);
    expect(member.isTeamLeader, isFalse);
    expect(member.teamName, 'FootMasters');
    expect(member.joinedAt, DateTime(2026, 7, 10, 10, 30));
  });

  test('팀이 없는 마이페이지 응답의 nullable 필드를 변환한다', () {
    final member = MemberMe.fromJson({
      'memberId': 11,
      'username': 'free-agent',
      'memberRating': 1400,
      'teamId': null,
      'teamName': null,
      'teamRole': null,
      'joinedAt': null,
      'createdAt': '2026-07-01T09:00:00',
    });

    expect(member.hasTeam, isFalse);
    expect(member.teamId, isNull);
    expect(member.joinedAt, isNull);
  });

  test('내 가입 신청 응답을 변환한다', () {
    final request = MyTeamJoinRequest.fromJson({
      'teamJoinRequestId': 7,
      'teamId': 3,
      'teamName': 'FootMasters',
      'memberId': 11,
      'username': 'free-agent',
      'status': 'PENDING',
      'createdAt': '2026-07-10T11:00:00',
    });

    expect(request.teamJoinRequestId, 7);
    expect(request.status, 'PENDING');
  });

  test('팀 탈퇴 응답을 변환한다', () {
    final result = TeamLeaveResult.fromJson({
      'memberId': 11,
      'username': 'player',
      'teamId': 3,
      'teamName': 'FootMasters',
      'teamRole': 'MEMBER',
      'left': true,
    });

    expect(result.left, isTrue);
    expect(result.teamRole, 'MEMBER');
  });
}
