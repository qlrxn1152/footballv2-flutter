import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

abstract interface class MemberDeviceTokenRepositoryContract {
  Future<void> register({required String token, required String platform});

  Future<void> unregister(String token);
}

class MemberDeviceTokenRepository
    implements MemberDeviceTokenRepositoryContract {
  const MemberDeviceTokenRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<void> register({required String token, required String platform}) {
    return runApi(() async {
      await _apiClient.dio.post<void>(
        '/api/device-tokens',
        data: {'token': token, 'platform': platform},
      );
    });
  }

  @override
  Future<void> unregister(String token) {
    return runApi(() async {
      await _apiClient.dio.delete<void>(
        '/api/device-tokens',
        queryParameters: {'token': token},
      );
    });
  }
}

final memberDeviceTokenRepositoryProvider =
    Provider<MemberDeviceTokenRepositoryContract>(
      (ref) => MemberDeviceTokenRepository(ref.watch(apiClientProvider)),
    );
