import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/config/brand_config.dart';
import 'package:footballv2_flutter/features/home/presentation/app_menu_drawer.dart';

void main() {
  testWidgets('축구공 메뉴에 주요 기능과 브랜드를 표시한다', (tester) async {
    var profileOpened = false;
    var announcementsOpened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              icon: const Icon(Icons.sports_soccer),
            ),
          ),
          endDrawer: AppMenuDrawer(
            username: 'test',
            isAdmin: true,
            onOpenProfile: () => profileOpened = true,
            onOpenGoals: () {},
            onOpenTeamBoard: () {},
            onOpenAnnouncements: () => announcementsOpened = true,
            onOpenAnalytics: () {},
            onShowAppInfo: () {},
            onLogout: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.sports_soccer));
    await tester.pumpAndSettle();

    expect(find.text(BrandConfig.name), findsOneWidget);
    expect(find.text(BrandConfig.slogan), findsOneWidget);
    expect(find.text('test님'), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-badge')), findsOneWidget);
    expect(find.text('내 정보'), findsOneWidget);
    expect(find.text('내 득점 기록'), findsOneWidget);
    expect(find.text('팀 게시판'), findsOneWidget);
    expect(find.text('공지사항'), findsOneWidget);
    expect(find.text('일별 사용 통계'), findsOneWidget);

    await tester.tap(find.text('내 정보'));
    expect(profileOpened, isTrue);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('공지사항'));
    expect(announcementsOpened, isTrue);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('앱 정보'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);
  });
}
