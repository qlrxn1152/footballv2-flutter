import 'package:flutter_test/flutter_test.dart';
import 'package:footballv2_flutter/features/announcements/data/announcement.dart';

void main() {
  test('공지사항 목록 응답을 변환한다', () {
    final announcement = AnnouncementSummary.fromJson({
      'announcementId': 7,
      'type': 'UPDATE',
      'title': '득점 기록 기능 추가',
      'version': '1.1.0',
      'pinned': true,
      'authorUsername': 'admin',
      'createdAt': '2026-07-15T20:30:00',
    });

    expect(announcement.announcementId, 7);
    expect(announcement.type, AnnouncementType.update);
    expect(announcement.type.label, '업데이트');
    expect(announcement.pinned, isTrue);
    expect(announcement.createdAt, DateTime(2026, 7, 15, 20, 30));
  });

  test('공지사항 작성 요청을 API 형식으로 변환한다', () {
    const input = AnnouncementCreateInput(
      type: AnnouncementType.maintenance,
      title: '서버 점검',
      content: '22시부터 점검합니다.',
      version: null,
      pinned: false,
    );

    expect(input.toJson(), {
      'announcementType': 'MAINTENANCE',
      'title': '서버 점검',
      'content': '22시부터 점검합니다.',
      'version': null,
      'pinned': false,
    });
  });
}
