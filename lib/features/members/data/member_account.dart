DateTime? _dateTime(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

class MemberMe {
  const MemberMe({
    required this.memberId,
    required this.username,
    required this.memberRating,
    this.authority = 'USER',
    required this.teamId,
    required this.teamName,
    required this.teamRole,
    required this.joinedAt,
    required this.createdAt,
  });

  final int memberId;
  final String username;
  final int memberRating;
  final String authority;
  final int? teamId;
  final String? teamName;
  final String? teamRole;
  final DateTime? joinedAt;
  final DateTime? createdAt;

  bool get hasTeam => teamId != null;
  bool get isTeamLeader => teamRole == 'LEADER';
  bool get isAdmin => authority == 'ADMIN';

  factory MemberMe.fromJson(Map<String, dynamic> json) {
    return MemberMe(
      memberId: (json['memberId'] as num).toInt(),
      username: json['username'] as String,
      memberRating: (json['memberRating'] as num).toInt(),
      authority: json['authority'] as String? ?? 'USER',
      teamId: (json['teamId'] as num?)?.toInt(),
      teamName: json['teamName'] as String?,
      teamRole: json['teamRole'] as String?,
      joinedAt: _dateTime(json['joinedAt']),
      createdAt: _dateTime(json['createdAt']),
    );
  }
}

class MyTeamJoinRequest {
  const MyTeamJoinRequest({
    required this.teamJoinRequestId,
    required this.teamId,
    required this.teamName,
    required this.memberId,
    required this.username,
    required this.status,
    required this.createdAt,
  });

  final int teamJoinRequestId;
  final int teamId;
  final String teamName;
  final int memberId;
  final String username;
  final String status;
  final DateTime? createdAt;

  factory MyTeamJoinRequest.fromJson(Map<String, dynamic> json) {
    return MyTeamJoinRequest(
      teamJoinRequestId: (json['teamJoinRequestId'] as num).toInt(),
      teamId: (json['teamId'] as num).toInt(),
      teamName: json['teamName'] as String,
      memberId: (json['memberId'] as num).toInt(),
      username: json['username'] as String,
      status: json['status'] as String,
      createdAt: _dateTime(json['createdAt']),
    );
  }
}

class TeamLeaveResult {
  const TeamLeaveResult({
    required this.memberId,
    required this.username,
    required this.teamId,
    required this.teamName,
    required this.teamRole,
    required this.left,
  });

  final int memberId;
  final String username;
  final int teamId;
  final String teamName;
  final String teamRole;
  final bool left;

  factory TeamLeaveResult.fromJson(Map<String, dynamic> json) {
    return TeamLeaveResult(
      memberId: (json['memberId'] as num).toInt(),
      username: json['username'] as String,
      teamId: (json['teamId'] as num).toInt(),
      teamName: json['teamName'] as String,
      teamRole: json['teamRole'] as String,
      left: json['left'] as bool,
    );
  }
}
