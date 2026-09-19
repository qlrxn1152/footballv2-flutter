enum FootmatchMatchStatus {
  pending('모집 중'),
  matched('매칭 완료'),
  completed('경기 완료');

  const FootmatchMatchStatus(this.label);
  final String label;
}

int? _intOrNull(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

DateTime? _dateTime(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '');

class FootmatchMatch {
  const FootmatchMatch({
    required this.id,
    required this.status,
    required this.homeName,
    required this.homeRating,
    required this.homeLeader,
    this.homeTeamId,
    this.awayTeamId,
    this.awayName,
    this.awayRating,
    this.awayLeader,
    this.playedAt,
    this.createdAt,
    this.winnerTeamName,
  });

  final int id;
  final FootmatchMatchStatus status;
  final int? homeTeamId;
  final String homeName;
  final int homeRating;
  final String homeLeader;
  final int? awayTeamId;
  final String? awayName;
  final int? awayRating;
  final String? awayLeader;
  final DateTime? playedAt;
  final DateTime? createdAt;
  final String? winnerTeamName;

  bool get isDraw =>
      status == FootmatchMatchStatus.completed && winnerTeamName == null;

  factory FootmatchMatch.fromJson(
    Map<String, dynamic> json,
    FootmatchMatchStatus status,
  ) {
    // Team-scoped pending responses use team*, whereas global lists use homeTeam*.
    return FootmatchMatch(
      id: (json['matchId'] as num).toInt(),
      status: status,
      homeTeamId: _intOrNull(json['homeTeamId'] ?? json['teamId']),
      homeName: (json['homeTeamName'] ?? json['teamName']) as String,
      homeRating:
          ((json['homeTeamRating'] ?? json['teamRating']) as num).toInt(),
      homeLeader:
          (json['homeTeamLeaderUsername'] ?? json['teamLeaderUsername'])
              as String,
      awayTeamId: _intOrNull(json['awayTeamId']),
      awayName: json['awayTeamName'] as String?,
      awayRating: _intOrNull(json['awayTeamRating']),
      awayLeader: json['awayTeamLeaderUsername'] as String?,
      playedAt: _dateTime(json['matchPlayedAt']),
      createdAt: _dateTime(json['matchCreatedAt']),
      winnerTeamName: json['winnerTeamName'] as String?,
    );
  }
}

class FootmatchMatchAcceptRequest {
  const FootmatchMatchAcceptRequest({
    required this.requestId,
    required this.requesterUsername,
    required this.requesterTeamName,
    required this.requesterTeamRating,
    required this.requestAt,
  });

  final int requestId;
  final String requesterUsername;
  final String requesterTeamName;
  final int requesterTeamRating;
  final DateTime? requestAt;

  factory FootmatchMatchAcceptRequest.fromJson(Map<String, dynamic> json) {
    return FootmatchMatchAcceptRequest(
      requestId: (json['requestId'] as num).toInt(),
      requesterUsername: json['requesterUsername'] as String,
      requesterTeamName: json['requesterTeamName'] as String,
      requesterTeamRating: (json['requesterTeamRating'] as num).toInt(),
      requestAt: _dateTime(json['requestAt']),
    );
  }
}

class FootmatchMatchResult {
  const FootmatchMatchResult({
    required this.matchResultId,
    required this.matchId,
    required this.homeScore,
    required this.homeTeamName,
    required this.awayScore,
    required this.awayTeamName,
    required this.winnerTeamName,
  });

  final int matchResultId;
  final int matchId;
  final int homeScore;
  final String homeTeamName;
  final int awayScore;
  final String awayTeamName;
  final String? winnerTeamName;

  bool get isDraw => winnerTeamName == null;

  factory FootmatchMatchResult.fromJson(Map<String, dynamic> json) {
    return FootmatchMatchResult(
      matchResultId: (json['matchResultId'] as num).toInt(),
      matchId: (json['matchId'] as num).toInt(),
      homeScore: (json['homeScore'] as num).toInt(),
      homeTeamName: json['homeTeamName'] as String,
      awayScore: (json['awayScore'] as num).toInt(),
      awayTeamName: json['awayTeamName'] as String,
      winnerTeamName: json['winnerTeamName'] as String?,
    );
  }
}
