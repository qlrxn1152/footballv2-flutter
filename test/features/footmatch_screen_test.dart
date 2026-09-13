import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/features/footmatch/data/footmatch_repository.dart';
import 'package:footballv2_flutter/features/footmatch/presentation/footmatch_screen.dart';

void main() {
  testWidgets('new home reads me and does not request legacy lists', (tester) async {
    final requests = <String>[];
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options.path);
      handler.resolve(Response<Object?>(requestOptions: options, statusCode: 200,
        data: {'memberId': 7, 'username': 'player7', 'rating': 1500},
      ));
    }));
    await tester.pumpWidget(ProviderScope(overrides: [
      footmatchRepositoryProvider.overrideWithValue(FootmatchRepository(dio)),
    ], child: const MaterialApp(home: FootmatchScreen())));
    await tester.pumpAndSettle();
    expect(find.text('player7'), findsOneWidget);
    expect(find.text('회원 번호 7'), findsOneWidget);
    await tester.tap(find.text('팀'));
    await tester.pumpAndSettle();
    expect(find.text('팀 조회'), findsOneWidget);
    expect(requests, ['/api/members/me']);
    expect(tester.takeException(), isNull);
  });
}
