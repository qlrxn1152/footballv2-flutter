DateTime? _dateTime(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

class TeamSummary {
  const TeamSummary({
    required this.teamId,
    required this.teamName,
    required this.teamRating,
    required this.leaderMemberId,
    required this.leaderUsername,
    required this.memberCount,
    required this.createdAt,
  });

  final int teamId;
  final String teamName;
  final int teamRating;
  final int leaderMemberId;
  final String leaderUsername;
  final int memberCount;
  final DateTime? createdAt;

  factory TeamSummary.fromJson(Map<String, dynamic> json) {
    return TeamSummary(
      teamId: (json['teamId'] as num).toInt(),
      teamName: json['teamName'] as String,
      teamRating: (json['teamRating'] as num).toInt(),
      leaderMemberId: (json['leaderMemberId'] as num).toInt(),
      leaderUsername: json['leaderUsername'] as String,
      memberCount: (json['memberCount'] as num).toInt(),
      createdAt: _dateTime(json['createdAt']),
    );
  }
}

class TeamDetail {
  const TeamDetail({
    required this.teamId,
    required this.teamName,
    required this.teamRating,
    required this.leaderMemberId,
    required this.leaderUsername,
    required this.memberCount,
    required this.createdAt,
  });

  final int teamId;
  final String teamName;
  final int teamRating;
  final int leaderMemberId;
  final String leaderUsername;
  final int memberCount;
  final DateTime? createdAt;

  factory TeamDetail.fromJson(Map<String, dynamic> json) {
    return TeamDetail(
      teamId: (json['teamId'] as num).toInt(),
      teamName: json['teamName'] as String,
      teamRating: (json['teamRating'] as num).toInt(),
      leaderMemberId: (json['leaderMemberId'] as num).toInt(),
      leaderUsername: json['leaderUsername'] as String,
      memberCount: (json['memberCount'] as num).toInt(),
      createdAt: _dateTime(json['createdAt']),
    );
  }
}

class TeamMember {
  const TeamMember({
    required this.teamMemberId,
    required this.teamId,
    required this.teamName,
    required this.memberId,
    required this.username,
    required this.memberRating,
    required this.teamRole,
    required this.joinedAt,
  });

  final int teamMemberId;
  final int teamId;
  final String teamName;
  final int memberId;
  final String username;
  final int memberRating;
  final String teamRole;
  final DateTime? joinedAt;

  bool get isLeader => teamRole == 'LEADER';

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      teamMemberId: (json['teamMemberId'] as num).toInt(),
      teamId: (json['teamId'] as num).toInt(),
      teamName: json['teamName'] as String,
      memberId: (json['memberId'] as num).toInt(),
      username: json['username'] as String,
      memberRating: (json['memberRating'] as num).toInt(),
      teamRole: json['teamRole'] as String,
      joinedAt: _dateTime(json['joinedAt']),
    );
  }
}

class TeamJoinRequest {
  const TeamJoinRequest({
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

  factory TeamJoinRequest.fromJson(Map<String, dynamic> json) {
    return TeamJoinRequest(
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
