import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/features/footmatch/data/footmatch_repository.dart';
import 'package:footballv2_flutter/features/footmatch/presentation/footmatch_screen.dart';

const myTeam = {'teamId': 3, 'teamName': '우리 FC', 'leaderId': 7,
  'leaderUsername': 'player7', 'teamRating': 1500, 'teamMemberCount': 1};
const otherTeam = {'teamId': 8, 'teamName': '다른 FC', 'leaderId': 8,
  'leaderUsername': 'player8', 'teamRating': 1600, 'teamMemberCount': 1};

Future<void> start(WidgetTester tester, List<String> requests,
    {bool noTeam = false, bool teamError = false}) async {
  final dio = Dio();
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    requests.add(options.path);
    if (teamError && options.path == '/api/teams/me') {
      handler.reject(DioException(requestOptions: options, type: DioExceptionType.badResponse,
        response: Response<Object?>(requestOptions: options, statusCode: 503,
          data: {'message': '내 팀 조회에 실패했습니다.'})));
      return;
    }
    final Object? data = switch (options.path) {
      '/api/members/me' => {'memberId': 7, 'username': 'player7', 'rating': 1500},
      '/api/members' => {'members': [{'memberId': 7, 'username': 'player7', 'rating': 1500}]},
      '/api/teams/me' => noTeam ? null : myTeam,
      '/api/teams' => {'teams': [myTeam, otherTeam]},
      '/api/teams/3' => myTeam,
      '/api/teams/8' => otherTeam,
      '/api/teams/3/members' || '/api/teams/8/members' => {'teamMembers': []},
      _ => {'${options.path.split('/').last}Matches': []},
    };
    handler.resolve(Response<Object?>(requestOptions: options,
      statusCode: data == null ? 204 : 200, data: data));
  }));
  await tester.pumpWidget(ProviderScope(overrides: [
    footmatchRepositoryProvider.overrideWithValue(FootmatchRepository(dio)),
  ], child: const MaterialApp(home: FootmatchScreen())));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('member tab separates directory from profile', (tester) async {
    final requests = <String>[];
    await start(tester, requests);
    expect(find.text('회원'), findsOneWidget);
    expect(find.text('전체 회원'), findsOneWidget);
    expect(find.text('player7'), findsOneWidget);
    await tester.tap(find.text('내 정보'));
    await tester.pumpAndSettle();
    expect(find.text('회원 번호 7'), findsOneWidget);
    expect(requests, contains('/api/members'));
    expect(requests, isNot(contains('/api/members/ranking')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('browsing another team never changes our team match scope', (tester) async {
    final requests = <String>[];
    await start(tester, requests);
    await tester.tap(find.text('팀'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다른 FC').first);
    await tester.pumpAndSettle();
    expect(requests, contains('/api/teams/8'));
    await tester.tap(find.text('경기'));
    await tester.pumpAndSettle();
    expect(requests.last, '/api/teams/3/matches/pending');
    await tester.tap(find.text('진행 중'));
    await tester.pumpAndSettle();
    expect(requests.last, '/api/teams/3/matches/matched');
    await tester.tap(find.text('종료'));
    await tester.pumpAndSettle();
    expect(requests.last, '/api/teams/3/matches/completed');
    await tester.tap(find.text('전체 팀'));
    await tester.pumpAndSettle();
    expect(requests.last, '/api/team-matches/pending');
    await tester.tap(find.text('진행 중'));
    await tester.pumpAndSettle();
    expect(requests.last, '/api/team-matches/matched');
    await tester.tap(find.text('종료'));
    await tester.pumpAndSettle();
    expect(requests.last, '/api/team-matches/completed');
    expect(tester.takeException(), isNull);
  });

  testWidgets('my team loads membership without entering a team number', (tester) async {
    final requests = <String>[];
    await start(tester, requests);
    await tester.tap(find.text('팀'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('내 팀'));
    await tester.pumpAndSettle();
    expect(requests, contains('/api/teams/3/members'));
    expect(find.text('팀 번호 3'), findsOneWidget);
    expect(find.text('팀 조회'), findsNothing);
  });

  testWidgets('a member without a team can still browse global matches', (tester) async {
    final requests = <String>[];
    await start(tester, requests, noTeam: true);
    await tester.tap(find.text('경기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('소속된 팀이 없습니다.'), findsOneWidget);
    expect(requests.any((path) => path.contains('/matches/')), isFalse);
    await tester.tap(find.text('전체 팀'));
    await tester.pumpAndSettle();
    expect(find.text('대기 중 경기가 없습니다.'), findsOneWidget);
  });

  testWidgets('membership failure is not presented as no membership', (tester) async {
    final requests = <String>[];
    await start(tester, requests, teamError: true);
    await tester.tap(find.text('경기'));
    await tester.pumpAndSettle();
    expect(find.text('내 팀 조회에 실패했습니다.'), findsOneWidget);
    expect(find.textContaining('소속된 팀이 없습니다.'), findsNothing);
    expect(find.text('내 팀 새로고침'), findsOneWidget);
  });
}
