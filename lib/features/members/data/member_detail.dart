class MemberDetail {
  const MemberDetail({
    required this.memberId,
    required this.username,
    required this.memberRating,
    required this.createdAt,
    this.teamId,
    this.teamName,
    this.teamRole,
    this.joinedAt,
  });

  final int memberId;
  final String username;
  final int memberRating;
  final int? teamId;
  final String? teamName;
  final String? teamRole;
  final DateTime? joinedAt;
  final DateTime createdAt;

  bool get hasTeam => teamId != null;
  bool get isLeader => teamRole == 'LEADER';

  factory MemberDetail.fromJson(Map<String, dynamic> json) {
    return MemberDetail(
      memberId: (json['memberId'] as num).toInt(),
      username: json['username'] as String,
      memberRating: (json['memberRating'] as num).toInt(),
      teamId: (json['teamId'] as num?)?.toInt(),
      teamName: json['teamName'] as String?,
      teamRole: json['teamRole'] as String?,
      joinedAt: _optionalDateTime(json['joinedAt']),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

DateTime? _optionalDateTime(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
