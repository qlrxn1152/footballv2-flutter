class TeamMatchHistory {
  const TeamMatchHistory({
    required this.teamMatchId,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.awayTeamId,
    required this.awayTeamName,
    required this.status,
    required this.createdAt,
    required this.playedAt,
    required this.homeScore,
    required this.awayScore,
    required this.winnerTeamId,
    required this.winnerTeamName,
  });

  final int teamMatchId;
  final int homeTeamId;
  final String homeTeamName;
  final int? awayTeamId;
  final String? awayTeamName;
  final String status;
  final DateTime? createdAt;
  final DateTime? playedAt;
  final int? homeScore;
  final int? awayScore;
  final int? winnerTeamId;
  final String? winnerTeamName;

  bool get isPending => status == 'PENDING';
  bool get isMatched => status == 'MATCHED';
  bool get isCompleted => status == 'COMPLETED';
  bool get hasResult => homeScore != null && awayScore != null;
  bool get isDraw => hasResult && homeScore == awayScore;

  bool includesTeam(int teamId) =>
      homeTeamId == teamId || awayTeamId == teamId;

  factory TeamMatchHistory.fromJson(Map<String, dynamic> json) {
    return TeamMatchHistory(
      teamMatchId: (json['teamMatchId'] as num).toInt(),
      homeTeamId: (json['homeTeamId'] as num).toInt(),
      homeTeamName: json['homeTeamName'] as String,
      awayTeamId: (json['awayTeamId'] as num?)?.toInt(),
      awayTeamName: json['awayTeamName'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      playedAt: DateTime.tryParse(json['playedAt']?.toString() ?? ''),
      homeScore: (json['homeScore'] as num?)?.toInt(),
      awayScore: (json['awayScore'] as num?)?.toInt(),
      winnerTeamId: (json['winnerTeamId'] as num?)?.toInt(),
      winnerTeamName: json['winnerTeamName'] as String?,
    );
  }
}
