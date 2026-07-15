enum AnnouncementType { notice, update, maintenance }

extension AnnouncementTypeValue on AnnouncementType {
  String get apiValue => switch (this) {
    AnnouncementType.notice => 'NOTICE',
    AnnouncementType.update => 'UPDATE',
    AnnouncementType.maintenance => 'MAINTENANCE',
  };

  String get label => switch (this) {
    AnnouncementType.notice => '공지',
    AnnouncementType.update => '업데이트',
    AnnouncementType.maintenance => '점검',
  };

  static AnnouncementType fromJson(Object? value) {
    return switch (value?.toString().toUpperCase()) {
      'UPDATE' => AnnouncementType.update,
      'MAINTENANCE' => AnnouncementType.maintenance,
      _ => AnnouncementType.notice,
    };
  }
}

DateTime? _dateTime(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

class AnnouncementSummary {
  const AnnouncementSummary({
    required this.announcementId,
    required this.type,
    required this.title,
    required this.version,
    required this.pinned,
    required this.authorUsername,
    required this.createdAt,
  });

  final int announcementId;
  final AnnouncementType type;
  final String title;
  final String? version;
  final bool pinned;
  final String authorUsername;
  final DateTime? createdAt;

  factory AnnouncementSummary.fromJson(Map<String, dynamic> json) {
    return AnnouncementSummary(
      announcementId: (json['announcementId'] as num).toInt(),
      type: AnnouncementTypeValue.fromJson(json['type']),
      title: json['title'] as String,
      version: json['version'] as String?,
      pinned: json['pinned'] as bool? ?? false,
      authorUsername: json['authorUsername'] as String? ?? '관리자',
      createdAt: _dateTime(json['createdAt']),
    );
  }
}

class AnnouncementDetail {
  const AnnouncementDetail({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.version,
    required this.pinned,
  });

  final int id;
  final AnnouncementType type;
  final String title;
  final String content;
  final String? version;
  final bool pinned;

  factory AnnouncementDetail.fromJson(Map<String, dynamic> json) {
    return AnnouncementDetail(
      id: (json['id'] as num).toInt(),
      type: AnnouncementTypeValue.fromJson(json['announcementType']),
      title: json['title'] as String,
      content: json['content'] as String,
      version: json['version'] as String?,
      pinned: json['pinned'] as bool? ?? false,
    );
  }
}

class AnnouncementCreateInput {
  const AnnouncementCreateInput({
    required this.type,
    required this.title,
    required this.content,
    required this.version,
    required this.pinned,
  });

  final AnnouncementType type;
  final String title;
  final String content;
  final String? version;
  final bool pinned;

  Map<String, dynamic> toJson() {
    return {
      'announcementType': type.apiValue,
      'title': title,
      'content': content,
      'version': version,
      'pinned': pinned,
    };
  }
}
