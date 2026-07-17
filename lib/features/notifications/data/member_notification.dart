class MemberNotification {
  const MemberNotification({
    required this.notificationId,
    required this.type,
    required this.title,
    required this.content,
    required this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  final int notificationId;
  final String type;
  final String title;
  final String content;
  final int? referenceId;
  final bool isRead;
  final DateTime? createdAt;

  bool get isUnread => !isRead;
  bool get opensMatch => type == 'MATCH_ACCEPTED' && referenceId != null;

  factory MemberNotification.fromJson(Map<String, dynamic> json) {
    return MemberNotification(
      notificationId: (json['notificationId'] as num).toInt(),
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      referenceId: (json['referenceId'] as num?)?.toInt(),
      isRead: json['read'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
