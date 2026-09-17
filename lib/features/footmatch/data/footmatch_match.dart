enum FootmatchMatchStatus {
  pending('모집 중'),
  matched('매칭 완료');

  const FootmatchMatchStatus(this.label);
  final String label;
}

class FootmatchMatch {
  const FootmatchMatch({
    required this.id,
    required this.status,
    required this.homeName,
    required this.homeRating,
    required this.homeLeader,
    this.awayName,
    this.awayRating,
    this.awayLeader,
    this.playedAt,
    this.createdAt,
  });

  final int id;
  final FootmatchMatchStatus status;
  final String homeName;
  final int homeRating;
  final String homeLeader;
  final String? awayName;
  final int? awayRating;
  final String? awayLeader;
  final DateTime? playedAt;
  final DateTime? createdAt;

  factory FootmatchMatch.fromJson(
      Map<String, dynamic> json, FootmatchMatchStatus status) {
    // Team-scoped pending responses use team*, whereas global lists use homeTeam*.
    return FootmatchMatch(
      id: (json['matchId'] as num).toInt(),
      status: status,
      homeName: (json['homeTeamName'] ?? json['teamName']) as String,
      homeRating: ((json['homeTeamRating'] ?? json['teamRating']) as num).toInt(),
      homeLeader: (json['homeTeamLeaderUsername'] ?? json['teamLeaderUsername']) as String,
      awayName: json['awayTeamName'] as String?,
      awayRating: (json['awayTeamRating'] as num?)?.toInt(),
      awayLeader: json['awayTeamLeaderUsername'] as String?,
      playedAt: DateTime.tryParse(json['matchPlayedAt']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['matchCreatedAt']?.toString() ?? ''),
    );
  }
}
