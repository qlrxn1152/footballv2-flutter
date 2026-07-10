import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'member_detail.dart';
import 'member_ranking.dart';

class MemberRepository {
  const MemberRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<MemberRanking>> fetchRankings() {
    return runApi(() async {
      final response = await _apiClient.dio.get<Object?>(
        '/api/members/ranking',
      );
      final data = response.data;
      if (data is! List) {
        throw const ApiException('선수 랭킹 응답 형식이 올바르지 않습니다.');
      }
      return data
          .map((item) => MemberRanking.fromJson(jsonMap(item)))
          .toList(growable: false);
    });
  }

  Future<MemberDetail> fetchMemberDetail(int memberId) {
    return runApi(() async {
      final response = await _apiClient.dio.get<Object?>(
        '/api/members/$memberId',
      );
      return MemberDetail.fromJson(jsonMap(response.data));
    });
  }
}

final memberRepositoryProvider = Provider<MemberRepository>(
  (ref) => MemberRepository(ref.watch(apiClientProvider)),
);

final memberRankingsProvider = FutureProvider<List<MemberRanking>>(
  (ref) => ref.watch(memberRepositoryProvider).fetchRankings(),
);

final memberDetailProvider = FutureProvider.family<MemberDetail, int>(
  (ref, memberId) =>
      ref.watch(memberRepositoryProvider).fetchMemberDetail(memberId),
);
