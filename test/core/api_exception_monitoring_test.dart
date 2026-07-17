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
}

DioException _error({
  int? statusCode,
  DioExceptionType type = DioExceptionType.badResponse,
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
        : Response<void>(requestOptions: options, statusCode: statusCode),
  );
}
