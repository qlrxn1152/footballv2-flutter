import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'announcement.dart';

class AnnouncementRepository {
  const AnnouncementRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<AnnouncementSummary>> fetchAnnouncements() {
    return runApi(() async {
      final response = await _apiClient.dio.get<Object?>(
        '/api/announcements',
      );
      final data = response.data;
      if (data is! List) {
        throw const ApiException('공지사항 목록 응답 형식이 올바르지 않습니다.');
      }
      final announcements = data
          .map((item) => AnnouncementSummary.fromJson(jsonMap(item)))
          .toList(growable: false);
      return announcements.toList()
        ..sort((a, b) {
          if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
    });
  }

  Future<AnnouncementDetail> fetchAnnouncementDetail(int id) {
    return runApi(() async {
      final response = await _apiClient.dio.get<Object?>(
        '/api/announcements/$id',
      );
      return AnnouncementDetail.fromJson(jsonMap(response.data));
    });
  }

  Future<AnnouncementDetail> createAnnouncement(
    AnnouncementCreateInput input,
  ) {
    return runApi(() async {
      final response = await _apiClient.dio.post<Object?>(
        '/api/admin/announcements',
        data: input.toJson(),
      );
      return AnnouncementDetail.fromJson(jsonMap(response.data));
    });
  }
}

final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => AnnouncementRepository(ref.watch(apiClientProvider)),
);

final announcementsProvider = FutureProvider.autoDispose<List<AnnouncementSummary>>(
  (ref) => ref.watch(announcementRepositoryProvider).fetchAnnouncements(),
);

final announcementDetailProvider =
    FutureProvider.autoDispose.family<AnnouncementDetail, int>(
      (ref, id) => ref
          .watch(announcementRepositoryProvider)
          .fetchAnnouncementDetail(id),
    );
