import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/features/team_posts/data/team_post.dart';

void main() {
  test('팀 게시글 요약 응답을 변환한다', () {
    final post = TeamPostSummary.fromJson({
      'postId': 11,
      'teamId': 3,
      'authorMemberId': 2,
      'title': '이번 주 경기 안내',
      'authorUsername': 'test',
      'createdAt': '2026-07-16T13:20:00',
    });

    expect(post.postId, 11);
    expect(post.teamId, 3);
    expect(post.authorMemberId, 2);
    expect(post.authorUsername, 'test');
    expect(post.createdAt, DateTime(2026, 7, 16, 13, 20));
  });

  test('팀 게시글 상세 응답을 변환한다', () {
    final post = TeamPostDetail.fromJson({
      'postId': 11,
      'teamId': 3,
      'authorMemberId': 2,
      'title': '이번 주 경기 안내',
      'content': '토요일 18시에 모입니다.',
      'authorUsername': 'test',
      'createdAt': '2026-07-16T13:20:00',
      'updatedAt': '2026-07-16T13:30:00',
    });

    expect(post.content, '토요일 18시에 모입니다.');
    expect(post.updatedAt, DateTime(2026, 7, 16, 13, 30));
  });

  test('게시글 작성 요청을 JSON으로 변환한다', () {
    const input = TeamPostInput(title: '제목', content: '내용');

    expect(input.toJson(), {'title': '제목', 'content': '내용'});
  });
}
