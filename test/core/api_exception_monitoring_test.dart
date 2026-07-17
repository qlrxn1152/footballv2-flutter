import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/core/network/api_exception.dart';

void main() {
  test('서버 오류와 연결 실패만 모니터링한다', () {
    expect(shouldReportApiFailure(_error(statusCode: 500)), isTrue);
    expect(shouldReportApiFailure(_error(statusCode: 503)), isTrue);
    expect(shouldReportApiFailure(_error(statusCode: 400)), isFalse);
    expect(shouldReportApiFailure(_error(statusCode: 401)), isFalse);
    expect(
      shouldReportApiFailure(
        _error(type: DioExceptionType.connectionError),
      ),
      isTrue,
    );
  });

  test('중요 기능은 400대 업무 오류도 모니터링한다', () {
    expect(
      shouldReportApiFailure(
        _error(statusCode: 400),
        importantAction: ImportantApiAction.teamCreate,
      ),
      isTrue,
    );
    expect(
      shouldReportApiFailure(
        _error(statusCode: 409),
        importantAction: ImportantApiAction.matchCreate,
      ),
      isTrue,
    );
  });

  test('모니터링 오류에는 요청 본문과 인증 헤더가 포함되지 않는다', () {
    const error = ApiMonitoringException(
      method: 'POST',
      path: '/api/team-matches',
      statusCode: 500,
      failureType: 'badResponse',
    );

    expect(error.toString(), contains('POST /api/team-matches'));
    expect(error.toString(), isNot(contains('Bearer')));
    expect(error.toString(), isNot(contains('password')));
  });

  test('중요 기능 실패에는 기능명과 안전한 서버 오류 코드만 포함한다', () {
    const error = ApiMonitoringException(
      method: 'POST',
      path: '/api/teams',
      statusCode: 409,
      failureType: 'badResponse',
      importantAction: ImportantApiAction.teamCreate,
      errorCode: 'TEAM_NAME_DUPLICATED',
    );

    expect(error.toString(), contains('TEAM_CREATE'));
    expect(error.toString(), contains('TEAM_NAME_DUPLICATED'));
    expect(error.toString(), isNot(contains('teamName')));
  });

  test('서버 오류 코드는 제한된 형식일 때만 사용한다', () {
    expect(
      safeApiErrorCodeForMonitoring(
        _error(statusCode: 409, data: {'code': 'TEAM_ALREADY_EXISTS'}),
      ),
      'TEAM_ALREADY_EXISTS',
    );
    expect(
      safeApiErrorCodeForMonitoring(
        _error(statusCode: 400, data: {'code': '사용자 입력값 포함'}),
      ),
      isNull,
    );
  });
}

DioException _error({
  int? statusCode,
  DioExceptionType type = DioExceptionType.badResponse,
  Object? data,
}) {
  final options = RequestOptions(
    path: '/api/test',
    method: 'GET',
    headers: {'Authorization': 'Bearer secret'},
    data: {'password': '1234'},
  );
  return DioException(
    requestOptions: options,
    type: type,
    response: statusCode == null
        ? null
        : Response<Object?>(
            requestOptions: options,
            statusCode: statusCode,
            data: data,
          ),
  );
}
