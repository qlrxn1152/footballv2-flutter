class TeamMatchCreateResult {
  const TeamMatchCreateResult({
    required this.teamMatchId,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.homeTeamRating,
    required this.status,
  });

  final int teamMatchId;
  final int homeTeamId;
  final String homeTeamName;
  final int homeTeamRating;
  final String status;

  bool get isPending => status == 'PENDING';

  factory TeamMatchCreateResult.fromJson(Map<String, dynamic> json) {
    return TeamMatchCreateResult(
      teamMatchId: (json['teamMatchId'] as num).toInt(),
      homeTeamId: (json['homeTeamId'] as num).toInt(),
      homeTeamName: json['homeTeamName'] as String,
      homeTeamRating: (json['homeTeamRating'] as num).toInt(),
      status: json['status'] as String,
    );
  }
}

class PendingTeamMatch {
  const PendingTeamMatch({
    required this.teamMatchId,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.homeTeamRating,
    required this.status,
    required this.createdAt,
  });

  final int teamMatchId;
  final int homeTeamId;
  final String homeTeamName;
  final int homeTeamRating;
  final String status;
  final DateTime? createdAt;

  factory PendingTeamMatch.fromJson(Map<String, dynamic> json) {
    return PendingTeamMatch(
      teamMatchId: (json['teamMatchId'] as num).toInt(),
      homeTeamId: (json['homeTeamId'] as num).toInt(),
      homeTeamName: json['homeTeamName'] as String,
      homeTeamRating: (json['homeTeamRating'] as num).toInt(),
      status: json['status'] as String,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
