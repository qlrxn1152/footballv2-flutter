import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/features/footmatch/data/footmatch_match.dart';
import 'package:footballv2_flutter/features/footmatch/data/footmatch_repository.dart';
import 'package:footballv2_flutter/features/footmatch/presentation/footmatch_match_list.dart';

const pending = {
  'matchId': 11, 'homeTeamName': '서울 FC', 'homeTeamRating': 1500,
  'homeTeamLeaderUsername': 'home', 'matchCreatedAt': '2026-09-17T10:00:00',
  'matchPlayedAt': '2026-09-20T19:00:00',
};
const matched = {
  'matchId': 12, 'homeTeamId': 3, 'homeTeamName': '서울 FC', 'homeTeamRating': 1500,
  'homeTeamLeaderUsername': 'home', 'matchCreatedAt': '2026-09-17T10:00:00',
  'matchPlayedAt': '2026-09-20T19:00:00', 'awayTeamId': 4, 'awayTeamName': '부산 FC',
  'awayTeamRating': 1600, 'awayTeamLeaderUsername': 'away',
};
const completed = {
  'matchId': 13, 'homeTeamId': 3, 'homeTeamName': '서울 FC', 'homeTeamRating': 1500,
  'homeTeamLeaderUsername': 'home', 'matchPlayedAt': '2026-09-19T19:00:00',
  'awayTeamId': 4, 'awayTeamName': '부산 FC', 'awayTeamRating': 1600,
  'awayTeamLeaderUsername': 'away', 'winnerTeamName': '서울 FC',
};

Widget app(FootmatchRepository repo, {int? teamId, ValueChanged<FootmatchMatch>? onRequest}) =>
    ProviderScope(overrides: [footmatchRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: Scaffold(body: SingleChildScrollView(
        child: FootmatchMatchList(teamId: teamId, onRequest: onRequest)))));

void main() {
  test('all four list endpoints decode their distinct DTOs', () async {
    final dio = Dio();
    final paths = <String>[];
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      paths.add(options.path);
      final isPending = options.path.endsWith('/pending');
      final isTeam = options.path.startsWith('/api/teams/');
      handler.resolve(Response<Object?>(requestOptions: options, data: {
        isPending ? 'pendingMatches' : 'matchedMatches': [
          if (!isPending) matched else if (!isTeam) pending else {
            'matchId': 11, 'teamId': 3, 'teamName': '서울 FC',
            'teamRating': 1500, 'teamLeaderUsername': 'home',
            'matchCreatedAt': '2026-09-17T10:00:00',
          },
        ],
      }));
    }));
    final repo = FootmatchRepository(dio);
    final globalPending = await repo.matches(FootmatchMatchStatus.pending);
    final globalMatched = await repo.matches(FootmatchMatchStatus.matched);
    final teamPending = await repo.matches(FootmatchMatchStatus.pending, teamId: 3);
    final teamMatched = await repo.matches(FootmatchMatchStatus.matched, teamId: 3);
    expect(paths, ['/api/team-matches/pending', '/api/team-matches/matched',
      '/api/teams/3/matches/pending', '/api/teams/3/matches/matched']);
    expect(globalPending.single.playedAt, DateTime(2026, 9, 20, 19));
    expect(globalMatched.single.awayName, '부산 FC');
    expect(teamPending.single.homeName, '서울 FC');
    expect(teamPending.single.playedAt, isNull);
    expect(teamMatched.single.awayRating, 1600);
  });

  test('completed lists and result registration follow the current backend contract', () async {
    final dio = Dio();
    final requests = <RequestOptions>[];
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      if (options.method == 'GET') {
        handler.resolve(Response<Object?>(
          requestOptions: options,
          data: {'completedMatches': [completed]},
        ));
        return;
      }
      handler.resolve(Response<Object?>(
        requestOptions: options,
        statusCode: 201,
        data: {
          'matchResultId': 21,
          'matchId': 13,
          'homeScore': 3,
          'homeTeamName': '서울 FC',
          'awayScore': 1,
          'awayTeamName': '부산 FC',
          'winnerTeamName': '서울 FC',
        },
      ));
    }));

    final repo = FootmatchRepository(dio);
    final global = await repo.matches(FootmatchMatchStatus.completed);
    final team = await repo.matches(FootmatchMatchStatus.completed, teamId: 3);
    final result = await repo.createMatchResult(
      matchId: 13,
      homeScore: 3,
      awayScore: 1,
    );

    expect(requests[0].path, '/api/team-matches/completed');
    expect(requests[1].path, '/api/teams/3/matches/completed');
    expect(requests[2].path, '/api/team-matches/13/result/score');
    expect(requests[2].data, {'homeScore': 3, 'awayScore': 1});
    expect(global.single.winnerTeamName, '서울 FC');
    expect(team.single.status, FootmatchMatchStatus.completed);
    expect(result.winnerTeamName, '서울 FC');
    expect(result.isDraw, isFalse);
  });

  test('member and team list endpoints decode wrapper responses', () async {
    final dio = Dio();
    final paths = <String>[];
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      paths.add(options.path);
      if (options.path == '/api/members/list') {
        handler.resolve(Response<Object?>(
          requestOptions: options,
          data: {
            'members': [
              {'id': 1, 'username': 'player1', 'rating': 1510},
              {'id': 2, 'username': 'player2', 'rating': 1480},
            ],
          },
        ));
        return;
      }
      handler.resolve(Response<Object?>(
        requestOptions: options,
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
    }));

    final repo = FootmatchRepository(dio);
    final members = await repo.memberList();
    final teams = await repo.teamList();

    expect(paths, ['/api/members/list', '/api/teams/list']);
    expect(members, hasLength(2));
    expect(members.first.id, 1);
    expect(members.first.username, 'player1');
    expect(members.first.rating, 1510);
    expect(teams.single.id, 3);
    expect(teams.single.teamName, '서울 FC');
    expect(teams.single.teamRating, 1600);
    expect(teams.single.leaderUsername, 'captain');
    expect(teams.single.memberCount, 8);
  });

  test('team match accept request list decodes request DTOs', () async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      expect(options.path, '/api/team-matches/3/request/pendings');
      handler.resolve(Response<Object?>(
        requestOptions: options,
        data: {
          'requests': [
            {
              'requestId': 42,
              'requesterUsername': 'awayLeader',
              'requesterTeamName': '부산 FC',
              'requesterTeamRating': 1600,
              'requestAt': '2026-09-19T18:00:00',
            },
          ],
        },
      ));
    }));

    final requests = await FootmatchRepository(dio).matchAcceptRequests(3);
    expect(requests.single.requestId, 42);
    expect(requests.single.requesterTeamName, '부산 FC');
  });

  test('acceptance uses match and request identifiers in the plural route', () async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      expect(options.method, 'POST');
      expect(options.path, '/api/team-matches/11/accept-requests/42');
      handler.resolve(Response<Object?>(requestOptions: options, data: {'matchId': 11}));
    }));
    await FootmatchRepository(dio).acceptMatch(11, 42);
  });

  test('old Railway routes remain usable during the backend rollout', () async {
    final dio = Dio();
    final paths = <String>[];
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      paths.add(options.path);
      if (options.path.startsWith('/api/team-matches/')) {
        handler.reject(DioException(requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<Object?>(requestOptions: options, statusCode: 404)));
      } else {
        handler.resolve(Response<Object?>(requestOptions: options, data: {'matchId': 11}));
      }
    }));
    final repo = FootmatchRepository(dio);
    await repo.createMatch(3, DateTime(2027));
    await repo.requestMatch(11);
    expect(paths, ['/api/team-matches/3/matches', '/api/team-match/3/matches',
      '/api/team-matches/11/accept-requests', '/api/team-match/11/accept-requests']);
  });

  test('auth, validation and network failures never retry mutations', () async {
    for (final status in [401, 403, 409, 500, null]) {
      final dio = Dio();
      var calls = 0;
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        calls++;
        handler.reject(DioException(requestOptions: options,
          type: status == null ? DioExceptionType.receiveTimeout : DioExceptionType.badResponse,
          response: status == null ? null : Response<Object?>(requestOptions: options, statusCode: status)));
      }));
      await expectLater(FootmatchRepository(dio).requestMatch(11), throwsException);
      expect(calls, 1);
    }
  });

  testWidgets('switch to matched hides participation and shows both teams', (tester) async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      handler.resolve(Response<Object?>(requestOptions: options, data:
        options.path.endsWith('/pending') ? {'pendingMatches': [pending]}
            : {'matchedMatches': [matched]}));
    }));
    int? requested;
    await tester.pumpWidget(app(FootmatchRepository(dio), onRequest: (m) => requested = m.id));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 경기 참가 신청'));
    expect(requested, 11);
    await tester.tap(find.text('매칭 완료'));
    await tester.pumpAndSettle();
    expect(find.text('서울 FC vs 부산 FC'), findsOneWidget);
    expect(find.text('경기 일시 2026-09-20 19:00'), findsOneWidget);
    expect(find.text('이 경기 참가 신청'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty state and retry recover from a failed request', (tester) async {
    final dio = Dio();
    var attempts = 0;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      if (attempts++ == 0) {
        handler.reject(DioException(requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<Object?>(requestOptions: options, statusCode: 503,
            data: {'message': '잠시 후 다시 시도해주세요.'})));
      } else {
        handler.resolve(Response<Object?>(requestOptions: options, data: {'pendingMatches': []}));
      }
    }));
    await tester.pumpWidget(app(FootmatchRepository(dio)));
    await tester.pumpAndSettle();
    expect(find.text('잠시 후 다시 시도해주세요.'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('모집 중 경기가 없습니다.'), findsOneWidget);
  });

  testWidgets('late pending response cannot replace a newer matched selection', (tester) async {
    final dio = Dio();
    final pendingHandler = Completer<RequestInterceptorHandler>();
    RequestOptions? pendingOptions;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      if (options.path.endsWith('/pending')) {
        pendingOptions = options;
        pendingHandler.complete(handler);
      } else {
        handler.resolve(Response<Object?>(requestOptions: options, data: {'matchedMatches': [matched]}));
      }
    }));
    await tester.pumpWidget(app(FootmatchRepository(dio)));
    await tester.pump();
    await tester.tap(find.text('매칭 완료'));
    await tester.pumpAndSettle();
    (await pendingHandler.future).resolve(Response<Object?>(
      requestOptions: pendingOptions!, data: {'pendingMatches': [pending]}));
    await tester.pumpAndSettle();
    expect(find.text('서울 FC vs 부산 FC'), findsOneWidget);
    expect(find.text('경기 번호 11 · 모집 중'), findsNothing);
  });
}
