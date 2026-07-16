class TeamPostComment {
  const TeamPostComment({
    required this.commentId,
    required this.postId,
    required this.authorMemberId,
    required this.authorUsername,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final int commentId;
  final int postId;
  final int authorMemberId;
  final String authorUsername;
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TeamPostComment.fromJson(Map<String, dynamic> json) {
    return TeamPostComment(
      commentId: (json['commentId'] as num).toInt(),
      postId: (json['postId'] as num).toInt(),
      authorMemberId: (json['authorMemberId'] as num).toInt(),
      authorUsername: json['authorUsername'] as String,
      content: json['content'] as String,
      createdAt: _dateTime(json['createdAt']),
      updatedAt: _dateTime(json['updatedAt']),
    );
  }
}

DateTime? _dateTime(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
