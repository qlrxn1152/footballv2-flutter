DateTime? _dateTime(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

class TeamPostSummary {
  const TeamPostSummary({
    required this.postId,
    required this.teamId,
    required this.authorMemberId,
    required this.title,
    required this.authorUsername,
    required this.createdAt,
  });

  final int postId;
  final int teamId;
  final int authorMemberId;
  final String title;
  final String authorUsername;
  final DateTime? createdAt;

  factory TeamPostSummary.fromJson(Map<String, dynamic> json) {
    return TeamPostSummary(
      postId: (json['postId'] as num).toInt(),
      teamId: (json['teamId'] as num).toInt(),
      authorMemberId: (json['authorMemberId'] as num).toInt(),
      title: json['title'] as String,
      authorUsername: json['authorUsername'] as String,
      createdAt: _dateTime(json['createdAt']),
    );
  }
}

class TeamPostDetail {
  const TeamPostDetail({
    required this.postId,
    required this.teamId,
    required this.authorMemberId,
    required this.title,
    required this.content,
    required this.authorUsername,
    required this.createdAt,
    required this.updatedAt,
  });

  final int postId;
  final int teamId;
  final int authorMemberId;
  final String title;
  final String content;
  final String authorUsername;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TeamPostDetail.fromJson(Map<String, dynamic> json) {
    return TeamPostDetail(
      postId: (json['postId'] as num).toInt(),
      teamId: (json['teamId'] as num).toInt(),
      authorMemberId: (json['authorMemberId'] as num).toInt(),
      title: json['title'] as String,
      content: json['content'] as String,
      authorUsername: json['authorUsername'] as String,
      createdAt: _dateTime(json['createdAt']),
      updatedAt: _dateTime(json['updatedAt']),
    );
  }
}

class TeamPostInput {
  const TeamPostInput({required this.title, required this.content});

  final String title;
  final String content;

  Map<String, dynamic> toJson() => {'title': title, 'content': content};
}
