import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/theme/app_theme.dart';
import 'package:footballv2_flutter/features/team_posts/data/team_post.dart';
import 'package:footballv2_flutter/features/team_posts/data/team_post_comment.dart';
import 'package:footballv2_flutter/features/team_posts/data/team_post_repository.dart';
import 'package:footballv2_flutter/features/team_posts/presentation/team_post_detail_screen.dart';
import 'package:footballv2_flutter/features/team_posts/presentation/team_post_list_screen.dart';

void main() {
  testWidgets('팀 게시판 목록과 글쓰기 버튼을 표시한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teamPostsProvider(3).overrideWith(
            (ref) async => [
              const TeamPostSummary(
                postId: 7,
                teamId: 3,
                authorMemberId: 2,
                title: '이번 주 경기 안내',
                authorUsername: 'test',
                createdAt: null,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const TeamPostListScreen(
            teamId: 3,
            teamName: 'teamA',
            currentMemberId: 2,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('teamA 라커룸'), findsOneWidget);
    expect(find.text('이번 주 경기 안내'), findsOneWidget);
    expect(find.text('내 글'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('team-post-create-button')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('작성자에게만 게시글 수정과 삭제 메뉴를 제공한다', (tester) async {
    const post = TeamPostDetail(
      postId: 7,
      teamId: 3,
      authorMemberId: 2,
      title: '이번 주 경기 안내',
      content: '토요일 18시에 모입니다.',
      authorUsername: 'test',
      createdAt: null,
      updatedAt: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teamPostDetailProvider(
            (teamId: 3, postId: 7),
          ).overrideWith((ref) async => post),
          teamPostCommentsProvider(
            (teamId: 3, postId: 7),
          ).overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const TeamPostDetailScreen(
            teamId: 3,
            postId: 7,
            currentMemberId: 2,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('team-post-author-menu')));
    await tester.pumpAndSettle();
    expect(find.text('게시글 수정'), findsOneWidget);
    expect(find.text('게시글 삭제'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('게시글 상세에서 댓글 목록과 입력창을 표시한다', (tester) async {
    const post = TeamPostDetail(
      postId: 7,
      teamId: 3,
      authorMemberId: 2,
      title: '이번 주 경기 안내',
      content: '토요일 18시에 모입니다.',
      authorUsername: 'test',
      createdAt: null,
      updatedAt: null,
    );
    const comment = TeamPostComment(
      commentId: 12,
      postId: 7,
      authorMemberId: 3,
      authorUsername: 'player',
      content: '참석합니다.',
      createdAt: null,
      updatedAt: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teamPostDetailProvider(
            (teamId: 3, postId: 7),
          ).overrideWith((ref) async => post),
          teamPostCommentsProvider(
            (teamId: 3, postId: 7),
          ).overrideWith((ref) async => const [comment]),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const TeamPostDetailScreen(
            teamId: 3,
            postId: 7,
            currentMemberId: 2,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('team-post-comment-field')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('댓글'), findsOneWidget);
    expect(find.text('참석합니다.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('team-post-comment-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('team-post-comment-submit-button')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('작성자에게만 댓글 수정과 삭제 메뉴를 제공한다', (tester) async {
    const post = TeamPostDetail(
      postId: 7,
      teamId: 3,
      authorMemberId: 2,
      title: '이번 주 경기 안내',
      content: '토요일 18시에 모입니다.',
      authorUsername: 'test',
      createdAt: null,
      updatedAt: null,
    );
    const myComment = TeamPostComment(
      commentId: 12,
      postId: 7,
      authorMemberId: 2,
      authorUsername: 'test',
      content: '참석합니다.',
      createdAt: null,
      updatedAt: null,
    );
    const otherComment = TeamPostComment(
      commentId: 13,
      postId: 7,
      authorMemberId: 3,
      authorUsername: 'player',
      content: '저도 참석합니다.',
      createdAt: null,
      updatedAt: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teamPostDetailProvider(
            (teamId: 3, postId: 7),
          ).overrideWith((ref) async => post),
          teamPostCommentsProvider(
            (teamId: 3, postId: 7),
          ).overrideWith((ref) async => const [myComment, otherComment]),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const TeamPostDetailScreen(
            teamId: 3,
            postId: 7,
            currentMemberId: 2,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final myCommentMenu = find.byKey(
      const ValueKey('team-post-comment-menu-12'),
    );
    await tester.ensureVisible(myCommentMenu);
    await tester.tap(myCommentMenu);
    await tester.pumpAndSettle();

    expect(find.text('댓글 수정'), findsOneWidget);
    expect(find.text('댓글 삭제'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('team-post-comment-menu-13')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
