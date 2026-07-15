import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/theme/app_theme.dart';
import 'package:footballv2_flutter/features/announcements/data/announcement.dart';
import 'package:footballv2_flutter/features/announcements/data/announcement_repository.dart';
import 'package:footballv2_flutter/features/announcements/presentation/announcement_list_screen.dart';

void main() {
  testWidgets('공지사항 목록과 관리자 작성 버튼을 표시한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          announcementsProvider.overrideWith(
            (ref) async => [
              AnnouncementSummary(
                announcementId: 1,
                type: AnnouncementType.update,
                title: '득점 기록 기능 추가',
                version: '1.1.0',
                pinned: true,
                authorUsername: 'admin',
                createdAt: DateTime(2026, 7, 15),
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AnnouncementListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('공지사항'), findsOneWidget);
    expect(find.text('풋볼로그 새 소식'), findsOneWidget);
    expect(find.text('득점 기록 기능 추가'), findsOneWidget);
    expect(find.text('업데이트'), findsOneWidget);
    expect(find.text('고정'), findsOneWidget);
    expect(find.text('관리자 작성'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
