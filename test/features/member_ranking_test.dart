import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/features/members/data/member_ranking.dart';

void main() {
  test('팀이 있는 멤버 랭킹 응답을 변환한다', () {
    final ranking = MemberRanking.fromJson({
      'rank': 1,
      'memberId': 10,
      'username': 'captain',
      'rating': 1800,
      'teamId': 3,
      'teamName': 'FootMasters',
    });

    expect(ranking.rank, 1);
    expect(ranking.rating, 1800);
    expect(ranking.teamId, 3);
    expect(ranking.teamName, 'FootMasters');
  });

  test('팀이 없는 멤버의 팀 필드는 null이다', () {
    final ranking = MemberRanking.fromJson({
      'rank': 2,
      'memberId': 11,
      'username': 'freeAgent',
      'rating': 1700,
      'teamId': null,
      'teamName': null,
    });

    expect(ranking.teamId, isNull);
    expect(ranking.teamName, isNull);
  });
}
