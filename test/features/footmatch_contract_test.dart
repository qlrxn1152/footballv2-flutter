import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/network/api_client.dart';
import 'package:footballv2_flutter/core/session/auth_session.dart';
import 'package:footballv2_flutter/core/session/session_store.dart';
import 'package:footballv2_flutter/features/auth/data/auth_repository.dart';
import 'package:footballv2_flutter/features/footmatch/data/footmatch_repository.dart';

void main() {
  test('Footmatch signup and login accept the deployed DTO without memberRating', () async {
    final store = _MemoryStore();
    final client = ApiClient(store);
    final requests = <RequestOptions>[];
    client.dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      handler.resolve(Response<Object?>(requestOptions: options, statusCode: 200,
        data: options.path == '/api/members' ? {'memberId': 7, 'username': 'player7'} : {
          'memberId': 7, 'username': 'player7', 'role': 'USER',
          'accessToken': 'new-token', 'tokenType': 'Bearer', 'expiresIn': 3600,
        },
      ));
    }));
    final auth = AuthRepository(client, store);
    await auth.signup(username: 'player7', password: 'pass1234');
    final session = await auth.login(username: 'player7', password: 'pass1234');
    expect(requests.map((r) => r.path), ['/api/members', '/api/auth/login']);
    expect(session.memberId, 7);
    expect(store.session?.accessToken, 'new-token');
    expect(requests.every((r) => !r.headers.containsKey('Authorization')), isTrue);
  });

  test('JWT is sent for member lookup but not signup or login', () async {
    final store = _MemoryStore();
    store.session = AuthSession(accessToken: 'existing', tokenType: 'Bearer',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      memberId: 1, username: 'user1', memberRating: 1500);
    final client = ApiClient(store);
    final requests = <RequestOptions>[];
    client.dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      handler.resolve(Response<Object?>(requestOptions: options, statusCode: 200, data: {}));
    }));
    await client.dio.get<Object?>('/api/members/me');
    await client.dio.post<Object?>('/api/members');
    await client.dio.post<Object?>('/api/auth/login');
    expect(requests[0].headers['Authorization'], 'Bearer existing');
    expect(requests[1].headers.containsKey('Authorization'), isFalse);
    expect(requests[2].headers.containsKey('Authorization'), isFalse);
    expect(requests.every((r) => !r.headers.containsKey('X-MEMBER-ID')), isTrue);
  });

  test('join requests use singular mutation paths and POST', () async {
    final dio = Dio();
    final requests = <RequestOptions>[];
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      handler.resolve(Response<Object?>(requestOptions: options, statusCode: 200,
          data: {'joinRequestId': 8, 'teamId': 3}));
    }));
    final repo = FootmatchRepository(dio);
    expect((await repo.join(3))['joinRequestId'], 8);
    await repo.acceptJoin(3, 8);
    await repo.rejectJoin(3, 8);
    await repo.cancelJoin(3, 8);
    expect(requests.map((r) => r.path), [
      '/api/teams/3/join-request', '/api/teams/3/join-request/8/accept',
      '/api/teams/3/join-request/8/reject', '/api/teams/3/join-request/8/cancel',
    ]);
    expect(requests.every((r) => r.method == 'POST'), isTrue);
  });

  test('match creation and participation follow Footmatch contract', () async {
    final dio = Dio();
    final requests = <RequestOptions>[];
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      handler.resolve(Response<Object?>(requestOptions: options, statusCode: 201,
          data: {'matchId': 9, 'requestId': 12}));
    }));
    final repo = FootmatchRepository(dio);
    await repo.createMatch(3, DateTime(2027, 1, 2, 19));
    await repo.requestMatch(9);
    expect(requests[0].path, '/api/team-matches/3/matches');
    expect(requests[0].data, {'playedAt': '2027-01-02T19:00:00.000'});
    expect(requests[1].path, '/api/team-matches/9/accept-requests');
    expect(requests[1].method, 'POST');
  });

  test('member kick accepts an empty successful response', () async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      expect(options.path, '/api/teams/3/members/7');
      expect(options.method, 'DELETE');
      handler.resolve(Response<Object?>(requestOptions: options, statusCode: 200));
    }));
    expect(await FootmatchRepository(dio).kick(3, 7), isEmpty);
  });
}

class _MemoryStore implements SessionStore {
  AuthSession? session;
  @override
  Future<void> clear() async { session = null; }
  @override
  Future<AuthSession?> read() async => session;
  @override
  Future<void> save(AuthSession value) async { session = value; }
}
