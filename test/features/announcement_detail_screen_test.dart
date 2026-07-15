import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/theme/app_theme.dart';
import 'package:footballv2_flutter/features/announcements/data/announcement.dart';
import 'package:footballv2_flutter/features/announcements/data/announcement_repository.dart';
import 'package:footballv2_flutter/features/announcements/presentation/announcement_detail_screen.dart';

void main() {
  testWidgets('공지 상세에서 관리자 수정과 삭제 메뉴를 제공한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          announcementDetailProvider(7).overrideWith(
            (ref) async => const AnnouncementDetail(
              id: 7,
              type: AnnouncementType.notice,
              title: '운영 공지',
              content: '공지 내용입니다.',
              version: '1.0.0',
              pinned: true,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AnnouncementDetailScreen(id: 7),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('운영 공지'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('announcement-admin-menu')),
    );
    await tester.pumpAndSettle();

    expect(find.text('공지 수정'), findsOneWidget);
    expect(find.text('공지 삭제'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
