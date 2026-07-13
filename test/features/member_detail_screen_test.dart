import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/features/members/data/member_detail.dart';
import 'package:footballv2_flutter/features/members/data/member_repository.dart';
import 'package:footballv2_flutter/features/members/presentation/member_detail_screen.dart';

void main() {
  testWidgets('선수 상세 화면에 총 득점을 표시한다', (tester) async {
    final member = MemberDetail.fromJson({
      'memberId': 2,
      'username': 'scorer',
      'memberRating': 1550,
      'totalGoalCount': 7,
      'teamId': null,
      'teamName': null,
      'teamRole': null,
      'joinedAt': null,
      'createdAt': '2026-07-08T09:00:00',
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memberDetailProvider(
            2,
          ).overrideWith((ref) async => member),
        ],
        child: const MaterialApp(home: MemberDetailScreen(memberId: 2)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('총 득점'), findsOneWidget);
    expect(find.text('7골'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
