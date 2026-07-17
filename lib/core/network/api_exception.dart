import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  factory ApiException.fromDio(DioException exception) {
    final data = exception.response?.data;
    if (data is Map) {
      return ApiException(
        data['message']?.toString() ?? '요청을 처리하지 못했습니다.',
        code: data['code']?.toString(),
        statusCode: exception.response?.statusCode,
      );
    }

    final message = switch (exception.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => '서버 응답 시간이 초과되었습니다.',
      DioExceptionType.connectionError =>
        '서버에 연결할 수 없습니다. 백엔드 실행 상태와 API 주소를 확인하세요.',
      _ => '네트워크 요청 중 오류가 발생했습니다.',
    };

    return ApiException(
      message,
      statusCode: exception.response?.statusCode,
    );
  }

  @override
  String toString() => message;
}

Future<T> runApi<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (error, stackTrace) {
    await _reportApiFailure(error, stackTrace);
    throw ApiException.fromDio(error);
  }
}

bool shouldReportApiFailure(DioException error) {
  final statusCode = error.response?.statusCode;
  if (statusCode != null) return statusCode >= 500;

  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError => true,
    _ => false,
  };
}

class ApiMonitoringException implements Exception {
  const ApiMonitoringException({
    required this.method,
    required this.path,
    required this.statusCode,
    required this.failureType,
  });

  final String method;
  final String path;
  final int? statusCode;
  final String failureType;

  @override
  String toString() {
    final status = statusCode == null ? 'no-status' : 'HTTP $statusCode';
    return 'API failure: $method $path ($status, $failureType)';
  }
}

Future<void> _reportApiFailure(
  DioException error,
  StackTrace stackTrace,
) async {
  if (!Sentry.isEnabled || !shouldReportApiFailure(error)) return;

  final request = error.requestOptions;
  final statusCode = error.response?.statusCode;
  final path = request.uri.path;
  final monitoringError = ApiMonitoringException(
    method: request.method,
    path: path,
    statusCode: statusCode,
    failureType: error.type.name,
  );

  try {
    await Sentry.captureException(
      monitoringError,
      stackTrace: stackTrace,
      withScope: (scope) async {
        await scope.setTag('http.request_method', request.method);
        await scope.setTag('http.route', path);
        await scope.setTag(
          'http.status_code',
          statusCode?.toString() ?? 'none',
        );
      },
    );
  } catch (_) {
    // Monitoring failures must never replace the original API error.
  }
}

Map<String, dynamic> jsonMap(Object? data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) {
    return data.map((key, value) => MapEntry(key.toString(), value));
  }
  throw const ApiException('서버 응답 형식이 올바르지 않습니다.');
}
