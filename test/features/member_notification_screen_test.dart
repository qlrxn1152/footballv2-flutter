import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/theme/app_theme.dart';
import 'package:footballv2_flutter/features/notifications/data/member_notification.dart';
import 'package:footballv2_flutter/features/notifications/data/member_notification_repository.dart';
import 'package:footballv2_flutter/features/notifications/presentation/member_notification_screen.dart';

void main() {
  testWidgets('읽지 않은 매치 알림과 하단 내비게이션을 표시한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memberNotificationsProvider.overrideWith(
            (ref) async => [
              MemberNotification(
                notificationId: 11,
                type: 'MATCH_ACCEPTED',
                title: '매치가 성사됐습니다.',
                content: '매치 성사 완료',
                referenceId: 23,
                isRead: false,
                createdAt: DateTime(2026, 7, 17, 12, 30),
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const MemberNotificationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('알림'), findsOneWidget);
    expect(find.text('경기 소식을 확인하세요'), findsOneWidget);
    expect(find.text('매치가 성사됐습니다.'), findsOneWidget);
    expect(find.text('매치 성사 완료'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('notification-11')),
      findsOneWidget,
    );
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('매치'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
