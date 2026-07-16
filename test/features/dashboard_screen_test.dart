import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/theme/app_theme.dart';
import 'package:footballv2_flutter/features/announcements/data/announcement.dart';
import 'package:footballv2_flutter/features/announcements/data/announcement_repository.dart';
import 'package:footballv2_flutter/features/home/presentation/dashboard_screen.dart';
import 'package:footballv2_flutter/features/matches/data/team_match.dart';
import 'package:footballv2_flutter/features/matches/data/team_match_repository.dart';
import 'package:footballv2_flutter/features/members/data/member_account.dart';
import 'package:footballv2_flutter/features/members/data/member_ranking.dart';
import 'package:footballv2_flutter/features/members/data/member_repository.dart';
import 'package:footballv2_flutter/features/team_posts/data/team_post_repository.dart';
import 'package:footballv2_flutter/features/teams/data/team_models.dart';
import 'package:footballv2_flutter/features/teams/data/team_repository.dart';

void main() {
  testWidgets('홈에서 내 팀과 주요 기능으로 이동할 수 있다', (tester) async {
    var selectedTab = -1;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memberMeProvider.overrideWith(
            (ref) async => const MemberMe(
              memberId: 1,
              username: 'test',
              memberRating: 1530,
              teamId: 3,
              teamName: 'teamA',
              teamRole: 'LEADER',
              joinedAt: null,
              createdAt: null,
            ),
          ),
          memberRankingsProvider.overrideWith(
            (ref) async => const [
              MemberRanking(
                rank: 1,
                memberId: 1,
                username: 'test',
                rating: 1530,
              ),
            ],
          ),
          teamsProvider.overrideWith(
            (ref) async => const [
              TeamSummary(
                teamId: 3,
                teamName: 'teamA',
                teamRating: 1560,
                leaderMemberId: 1,
                leaderUsername: 'test',
                memberCount: 5,
                createdAt: null,
              ),
            ],
          ),
          allTeamMatchesProvider.overrideWith(
            (ref) async => [
              TeamMatchSummary(
                teamMatchId: 9,
                homeTeamId: 3,
                homeTeamName: 'teamA',
                homeTeamRating: 1560,
                awayTeamId: 4,
                awayTeamName: 'teamB',
                awayTeamRating: 1500,
                homeScore: null,
                awayScore: null,
                winnerTeamId: null,
                winnerTeamName: null,
                status: 'MATCHED',
                createdAt: DateTime(2026, 7, 15),
                playedAt: DateTime(2099, 7, 20, 19),
              ),
            ],
          ),
          announcementsProvider.overrideWith(
            (ref) async => [
              AnnouncementSummary(
                announcementId: 2,
                type: AnnouncementType.notice,
                title: '풋볼로그 운영 안내',
                version: null,
                pinned: true,
                authorUsername: 'test',
                createdAt: DateTime(2026, 7, 15),
              ),
            ],
          ),
          teamPostsProvider(3).overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: DashboardScreen(
              onSelectTab: (index) => selectedTab = index,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('test님, 오늘도 뛰어볼까요?'), findsOneWidget);
    expect(find.text('teamA'), findsWidgets);
    expect(find.text('빠른 메뉴'), findsOneWidget);
    expect(find.text('teamA 게시판'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard-team-board-action')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('dashboard-members-action')),
    );
    expect(selectedTab, 1);

    await tester.scrollUntilVisible(
      find.text('다가오는 경기'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('teamB'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('풋볼로그 운영 안내'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('오늘의 순위'), findsOneWidget);
    expect(find.text('풋볼로그 운영 안내'), findsOneWidget);

    final teamBoardAction = find.byKey(
      const ValueKey('dashboard-team-board-action'),
    );
    await tester.ensureVisible(teamBoardAction);
    await tester.pumpAndSettle();
    await tester.tap(teamBoardAction);
    await tester.pumpAndSettle();
    expect(find.text('teamA 라커룸'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
