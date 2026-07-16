import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/features/team_posts/data/team_post_comment.dart';

void main() {
  test('팀 게시글 댓글 응답을 변환한다', () {
    final comment = TeamPostComment.fromJson({
      'commentId': 12,
      'postId': 7,
      'authorMemberId': 2,
      'authorUsername': 'test',
      'content': '참석합니다.',
      'createdAt': '2026-07-16T15:10:00',
      'updatedAt': '2026-07-16T15:10:00',
    });

    expect(comment.commentId, 12);
    expect(comment.postId, 7);
    expect(comment.authorMemberId, 2);
    expect(comment.content, '참석합니다.');
    expect(comment.createdAt, DateTime(2026, 7, 16, 15, 10));
  });
}
