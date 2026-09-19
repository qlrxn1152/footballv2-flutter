import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/features/footmatch/data/footmatch_repository.dart';
import 'package:footballv2_flutter/features/footmatch/presentation/footmatch_screen.dart';

void main() {
  testWidgets('home loads member and team directories with my profile', (tester) async {
    final requests = <String>[];
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options.path);

      if (options.path == '/api/members/me') {
        handler.resolve(Response<Object?>(
          requestOptions: options,
          statusCode: 200,
          data: {'memberId': 7, 'username': 'player7', 'rating': 1500},
        ));
        return;
      }

      if (options.path == '/api/members/list') {
        handler.resolve(Response<Object?>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'members': [
              {'id': 7, 'username': 'player7', 'rating': 1500},
              {'id': 8, 'username': 'player8', 'rating': 1480},
            ],
          },
        ));
        return;
      }

      if (options.path == '/api/teams/list') {
        handler.resolve(Response<Object?>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'teams': [
              {
                'id': 3,
                'teamName': '서울 FC',
                'teamRating': 1600,
                'leaderUsername': 'captain',
                'memberCount': 8,
              },
            ],
          },
        ));
        return;
      }

      handler.resolve(Response<Object?>(
        requestOptions: options,
        statusCode: 200,
        data: {},
      ));
    }));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        footmatchRepositoryProvider.overrideWithValue(FootmatchRepository(dio)),
      ],
      child: const MaterialApp(home: FootmatchScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('전체 회원'), findsOneWidget);
    expect(find.text('player7'), findsWidgets);
    expect(find.text('회원 번호 7'), findsWidgets);

    await tester.tap(find.text('팀'));
    await tester.pumpAndSettle();

    expect(find.text('전체 팀'), findsOneWidget);
    expect(find.text('서울 FC'), findsOneWidget);
    expect(find.text('팀 #3 · 팀장 captain · 8명'), findsOneWidget);
    expect(find.text('팀 조회'), findsOneWidget);

    expect(
      requests,
      ['/api/members/me', '/api/members/list', '/api/teams/list'],
    );
    expect(tester.takeException(), isNull);
  });
}
