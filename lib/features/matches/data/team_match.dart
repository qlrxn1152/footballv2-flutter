class TeamMatchCreateResult {
  const TeamMatchCreateResult({
    required this.teamMatchId,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.homeTeamRating,
    required this.status,
    required this.playedAt,
    required this.createdAt,
  });

  final int teamMatchId;
  final int homeTeamId;
  final String homeTeamName;
  final int homeTeamRating;
  final String status;
  final DateTime? playedAt;
  final DateTime? createdAt;

  bool get isPending => status == 'PENDING';

  factory TeamMatchCreateResult.fromJson(Map<String, dynamic> json) {
    return TeamMatchCreateResult(
      teamMatchId: (json['teamMatchId'] as num).toInt(),
      homeTeamId: (json['homeTeamId'] as num).toInt(),
      homeTeamName: json['homeTeamName'] as String,
      homeTeamRating: (json['homeTeamRating'] as num).toInt(),
      status: json['status'] as String,
      playedAt: DateTime.tryParse(json['playedAt']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class TeamMatchSummary {
  const TeamMatchSummary({
    required this.teamMatchId,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.homeTeamRating,
    required this.awayTeamId,
    required this.awayTeamName,
    required this.awayTeamRating,
    required this.homeScore,
    required this.awayScore,
    required this.winnerTeamId,
    required this.winnerTeamName,
    required this.status,
    required this.createdAt,
    required this.playedAt,
  });

  final int teamMatchId;
  final int homeTeamId;
  final String homeTeamName;
  final int homeTeamRating;
  final int? awayTeamId;
  final String? awayTeamName;
  final int? awayTeamRating;
  final int? homeScore;
  final int? awayScore;
  final int? winnerTeamId;
  final String? winnerTeamName;
  final String status;
  final DateTime? createdAt;
  final DateTime? playedAt;

  bool get isPending => status == 'PENDING';
  bool get isMatched => status == 'MATCHED';
  bool get isCompleted => status == 'COMPLETED';
  bool get hasResult => homeScore != null && awayScore != null;
  bool get isDraw => hasResult && homeScore == awayScore;

  bool includesTeam(int teamId) =>
      homeTeamId == teamId || awayTeamId == teamId;

  factory TeamMatchSummary.fromJson(Map<String, dynamic> json) {
    return TeamMatchSummary(
      teamMatchId: (json['teamMatchId'] as num).toInt(),
      homeTeamId: (json['homeTeamId'] as num).toInt(),
      homeTeamName: json['homeTeamName'] as String,
      homeTeamRating: (json['homeTeamRating'] as num).toInt(),
      awayTeamId: (json['awayTeamId'] as num?)?.toInt(),
      awayTeamName: json['awayTeamName'] as String?,
      awayTeamRating: (json['awayTeamRating'] as num?)?.toInt(),
      homeScore: (json['homeScore'] as num?)?.toInt(),
      awayScore: (json['awayScore'] as num?)?.toInt(),
      winnerTeamId: (json['winnerTeamId'] as num?)?.toInt(),
      winnerTeamName: json['winnerTeamName'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      playedAt: DateTime.tryParse(json['playedAt']?.toString() ?? ''),
    );
  }
}

class TeamMatchDetail {
  const TeamMatchDetail({
    required this.teamMatchId,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.homeTeamRating,
    required this.awayTeamId,
    required this.awayTeamName,
    required this.awayTeamRating,
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
  final int homeTeamRating;
  final int? awayTeamId;
  final String? awayTeamName;
  final int? awayTeamRating;
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

  factory TeamMatchDetail.fromJson(Map<String, dynamic> json) {
    return TeamMatchDetail(
      teamMatchId: (json['teamMatchId'] as num).toInt(),
      homeTeamId: (json['homeTeamId'] as num).toInt(),
      homeTeamName: json['homeTeamName'] as String,
      homeTeamRating: (json['homeTeamRating'] as num).toInt(),
      awayTeamId: (json['awayTeamId'] as num?)?.toInt(),
      awayTeamName: json['awayTeamName'] as String?,
      awayTeamRating: (json['awayTeamRating'] as num?)?.toInt(),
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

class TeamMatchAcceptResult {
  const TeamMatchAcceptResult({
    required this.teamMatchId,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.homeTeamRating,
    required this.awayTeamId,
    required this.awayTeamName,
    required this.awayTeamRating,
    required this.status,
  });

  final int teamMatchId;
  final int homeTeamId;
  final String homeTeamName;
  final int homeTeamRating;
  final int awayTeamId;
  final String awayTeamName;
  final int awayTeamRating;
  final String status;

  factory TeamMatchAcceptResult.fromJson(Map<String, dynamic> json) {
    return TeamMatchAcceptResult(
      teamMatchId: (json['teamMatchId'] as num).toInt(),
      homeTeamId: (json['homeTeamId'] as num).toInt(),
      homeTeamName: json['homeTeamName'] as String,
      homeTeamRating: (json['homeTeamRating'] as num).toInt(),
      awayTeamId: (json['awayTeamId'] as num).toInt(),
      awayTeamName: json['awayTeamName'] as String,
      awayTeamRating: (json['awayTeamRating'] as num).toInt(),
      status: json['status'] as String,
    );
  }
}

class TeamMatchGoalInput {
  const TeamMatchGoalInput({
    required this.teamId,
    required this.scorerMemberId,
    required this.goalCount,
  });

  final int teamId;
  final int scorerMemberId;
  final int goalCount;

  Map<String, dynamic> toJson() => {
    'teamId': teamId,
    'scorerMemberId': scorerMemberId,
    'goalCount': goalCount,
  };
}

class TeamMatchGoal {
  const TeamMatchGoal({
    required this.teamId,
    required this.teamMatchId,
    required this.scorerMemberId,
    required this.scorerUsername,
    required this.goalCount,
  });

  final int teamId;
  final int teamMatchId;
  final int scorerMemberId;
  final String scorerUsername;
  final int goalCount;

  factory TeamMatchGoal.fromJson(Map<String, dynamic> json) {
    return TeamMatchGoal(
      teamId: (json['teamId'] as num).toInt(),
      teamMatchId: (json['teamMatchId'] as num).toInt(),
      scorerMemberId: (json['scorerMemberId'] as num).toInt(),
      scorerUsername: json['scorerUsername'] as String,
      goalCount: (json['goalCount'] as num).toInt(),
    );
  }
}

class TeamMatchResult {
  const TeamMatchResult({
    required this.teamMatchId,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.homeScore,
    required this.awayTeamId,
    required this.awayTeamName,
    required this.awayScore,
    required this.winnerTeamId,
    required this.winnerTeamName,
    required this.status,
    required this.goals,
  });

  final int teamMatchId;
  final int homeTeamId;
  final String homeTeamName;
  final int homeScore;
  final int awayTeamId;
  final String awayTeamName;
  final int awayScore;
  final int? winnerTeamId;
  final String? winnerTeamName;
  final String status;
  final List<TeamMatchGoal> goals;

  bool get isDraw => winnerTeamId == null;
  bool get isCompleted => status == 'COMPLETED';

  factory TeamMatchResult.fromJson(Map<String, dynamic> json) {
    return TeamMatchResult(
      teamMatchId: (json['teamMatchId'] as num).toInt(),
      homeTeamId: (json['homeTeamId'] as num).toInt(),
      homeTeamName: json['homeTeamName'] as String,
      homeScore: (json['homeScore'] as num).toInt(),
      awayTeamId: (json['awayTeamId'] as num).toInt(),
      awayTeamName: json['awayTeamName'] as String,
      awayScore: (json['awayScore'] as num).toInt(),
      winnerTeamId: (json['winnerTeamId'] as num?)?.toInt(),
      winnerTeamName: json['winnerTeamName'] as String?,
      status: json['status'] as String,
      goals: (json['goals'] as List<dynamic>? ?? const [])
          .map((item) => TeamMatchGoal.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
