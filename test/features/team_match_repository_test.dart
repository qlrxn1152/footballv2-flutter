import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/network/api_client.dart';
import 'package:footballv2_flutter/core/session/auth_session.dart';
import 'package:footballv2_flutter/core/session/session_store.dart';
import 'package:footballv2_flutter/features/matches/data/team_match_repository.dart';

void main() {
  test('매치 등록 요청에 경기 일시와 경기장 정보를 함께 전송한다', () async {
    final apiClient = ApiClient(_EmptySessionStore());
    RequestOptions? capturedRequest;
    apiClient.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 201,
              data: {
                'teamMatchId': 12,
                'homeTeamId': 3,
                'homeTeamName': 'teamA',
                'homeTeamRating': 1500,
                'status': 'PENDING',
                'playedAt': '2026-07-20T18:30:00',
                'createdAt': '2026-07-18T10:00:00',
                'stadiumName': '월드컵 풋살장',
                'stadiumAddress': '서울시 마포구 월드컵로 1',
              },
            ),
          );
        },
      ),
    );
    final repository = TeamMatchRepository(apiClient);

    final result = await repository.createMatch(
      teamId: 3,
      playedAt: DateTime(2026, 7, 20, 18, 30),
      stadiumName: '월드컵 풋살장',
      stadiumAddress: '서울시 마포구 월드컵로 1',
    );

    expect(capturedRequest?.method, 'POST');
    expect(capturedRequest?.path, '/api/teams/3/matches');
    expect(capturedRequest?.data, {
      'playedAt': '2026-07-20T18:30:00.000',
      'stadiumName': '월드컵 풋살장',
      'stadiumAddress': '서울시 마포구 월드컵로 1',
    });
    expect(result.stadiumName, '월드컵 풋살장');
  });
}

class _EmptySessionStore implements SessionStore {
  @override
  Future<void> clear() async {}

  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> save(AuthSession session) async {}
}
