import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/theme/app_theme.dart';
import 'package:footballv2_flutter/features/team_posts/data/team_post.dart';
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
}
