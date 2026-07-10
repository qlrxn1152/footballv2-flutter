DateTime? _dateTime(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

Object? _firstValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null) return value;
  }
  return null;
}

int _requiredInt(
  Map<String, dynamic> json,
  List<String> keys,
  String fieldName,
) {
  final value = _firstValue(json, keys);
  if (value is num) return value.toInt();
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed != null) return parsed;
  throw FormatException('$fieldName 값이 없거나 숫자가 아닙니다.');
}

int _intOrZero(Map<String, dynamic> json, List<String> keys) {
  final value = _firstValue(json, keys);
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _requiredString(
  Map<String, dynamic> json,
  List<String> keys,
  String fieldName,
) {
  final value = _firstValue(json, keys)?.toString().trim();
  if (value != null && value.isNotEmpty) return value;
  throw FormatException('$fieldName 값이 없습니다.');
}

String _stringOr(
  Map<String, dynamic> json,
  List<String> keys,
  String fallback,
) {
  final value = _firstValue(json, keys)?.toString().trim();
  return value == null || value.isEmpty ? fallback : value;
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
      teamId: _requiredInt(json, const ['teamId', 'id'], 'teamId'),
      teamName: _requiredString(
        json,
        const ['teamName', 'name'],
        'teamName',
      ),
      teamRating: _intOrZero(json, const ['teamRating', 'rating']),
      leaderMemberId: _intOrZero(
        json,
        const ['leaderMemberId', 'leaderId'],
      ),
      leaderUsername: _stringOr(
        json,
        const ['leaderUsername', 'leaderName'],
        '리더 정보 없음',
      ),
      memberCount: _intOrZero(
        json,
        const ['memberCount', 'teamMemberCount'],
      ),
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
      teamId: _requiredInt(json, const ['teamId', 'id'], 'teamId'),
      teamName: _requiredString(
        json,
        const ['teamName', 'name'],
        'teamName',
      ),
      teamRating: _intOrZero(json, const ['teamRating', 'rating']),
      leaderMemberId: _intOrZero(
        json,
        const ['leaderMemberId', 'leaderId'],
      ),
      leaderUsername: _stringOr(
        json,
        const ['leaderUsername', 'leaderName'],
        '리더 정보 없음',
      ),
      memberCount: _intOrZero(
        json,
        const ['memberCount', 'teamMemberCount'],
      ),
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

class TeamLeaderTransferResult {
  const TeamLeaderTransferResult({
    required this.teamId,
    required this.teamName,
    required this.oldLeaderMemberId,
    required this.oldLeaderUsername,
    required this.newLeaderMemberId,
    required this.newLeaderUsername,
  });

  final int teamId;
  final String teamName;
  final int oldLeaderMemberId;
  final String oldLeaderUsername;
  final int newLeaderMemberId;
  final String newLeaderUsername;

  factory TeamLeaderTransferResult.fromJson(Map<String, dynamic> json) {
    return TeamLeaderTransferResult(
      teamId: _requiredInt(json, const ['teamId'], 'teamId'),
      teamName: _requiredString(json, const ['teamName'], 'teamName'),
      oldLeaderMemberId: _requiredInt(
        json,
        const ['oldLeaderMemberId'],
        'oldLeaderMemberId',
      ),
      oldLeaderUsername: _requiredString(
        json,
        const ['oldLeaderUsername'],
        'oldLeaderUsername',
      ),
      newLeaderMemberId: _requiredInt(
        json,
        const ['newLeaderMemberId'],
        'newLeaderMemberId',
      ),
      newLeaderUsername: _requiredString(
        json,
        const ['newLeaderUsername'],
        'newLeaderUsername',
      ),
    );
  }
}

class TeamNameUpdateResult {
  const TeamNameUpdateResult({
    required this.teamId,
    required this.teamName,
    required this.teamRating,
    required this.leaderMemberId,
    required this.leaderUsername,
  });

  final int teamId;
  final String teamName;
  final int teamRating;
  final int leaderMemberId;
  final String leaderUsername;

  factory TeamNameUpdateResult.fromJson(Map<String, dynamic> json) {
    return TeamNameUpdateResult(
      teamId: _requiredInt(json, const ['teamId'], 'teamId'),
      teamName: _requiredString(json, const ['teamName'], 'teamName'),
      teamRating: _requiredInt(
        json,
        const ['teamRating'],
        'teamRating',
      ),
      leaderMemberId: _requiredInt(
        json,
        const ['leaderMemberId'],
        'leaderMemberId',
      ),
      leaderUsername: _requiredString(
        json,
        const ['leaderUsername'],
        'leaderUsername',
      ),
    );
  }
}

class TeamDisbandResult {
  const TeamDisbandResult({
    required this.teamId,
    required this.teamName,
    required this.leaderMemberId,
    required this.leaderUsername,
    required this.disbanded,
  });

  final int teamId;
  final String teamName;
  final int leaderMemberId;
  final String leaderUsername;
  final bool disbanded;

  factory TeamDisbandResult.fromJson(Map<String, dynamic> json) {
    return TeamDisbandResult(
      teamId: _requiredInt(json, const ['teamId'], 'teamId'),
      teamName: _requiredString(json, const ['teamName'], 'teamName'),
      leaderMemberId: _requiredInt(
        json,
        const ['leaderMemberId'],
        'leaderMemberId',
      ),
      leaderUsername: _requiredString(
        json,
        const ['leaderUsername'],
        'leaderUsername',
      ),
      disbanded: json['disbanded'] as bool? ?? false,
    );
  }
}
