import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'member_account.dart';
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

  Future<MemberMe> fetchMe() {
    return runApi(() async {
      final response = await _apiClient.dio.get<Object?>('/api/members/me');
      return MemberMe.fromJson(jsonMap(response.data));
    });
  }

  Future<List<MyTeamJoinRequest>> fetchMyTeamJoinRequests() {
    return runApi(() async {
      final response = await _apiClient.dio.get<Object?>(
        '/api/members/me/team-join-requests',
      );
      final data = response.data;
      if (data is! List) {
        throw const ApiException('내 가입 신청 응답 형식이 올바르지 않습니다.');
      }
      return data
          .map((item) => MyTeamJoinRequest.fromJson(jsonMap(item)))
          .toList(growable: false);
    });
  }

  Future<MyTeamJoinRequest> cancelMyTeamJoinRequest(int joinRequestId) {
    return runApi(() async {
      final response = await _apiClient.dio.patch<Object?>(
        '/api/members/me/team-join-requests/$joinRequestId/cancel',
      );
      return MyTeamJoinRequest.fromJson(jsonMap(response.data));
    });
  }

  Future<TeamLeaveResult> leaveTeam() {
    return runApi(() async {
      final response = await _apiClient.dio.delete<Object?>(
        '/api/members/me/team',
      );
      return TeamLeaveResult.fromJson(jsonMap(response.data));
    });
  }
}

final memberRepositoryProvider = Provider<MemberRepository>(
  (ref) => MemberRepository(ref.watch(apiClientProvider)),
);

final memberRankingsProvider = FutureProvider.autoDispose<List<MemberRanking>>(
  (ref) => ref.watch(memberRepositoryProvider).fetchRankings(),
);

final memberDetailProvider =
    FutureProvider.autoDispose.family<MemberDetail, int>(
      (ref, memberId) =>
          ref.watch(memberRepositoryProvider).fetchMemberDetail(memberId),
    );

final memberMeProvider = FutureProvider.autoDispose<MemberMe>(
  (ref) => ref.watch(memberRepositoryProvider).fetchMe(),
);

final myTeamJoinRequestsProvider =
    FutureProvider.autoDispose<List<MyTeamJoinRequest>>(
      (ref) => ref.watch(memberRepositoryProvider).fetchMyTeamJoinRequests(),
    );
