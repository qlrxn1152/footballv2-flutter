class FootmatchMemberListItem {
  const FootmatchMemberListItem({
    required this.id,
    required this.username,
    required this.rating,
  });

  final int id;
  final String username;
  final int rating;

  factory FootmatchMemberListItem.fromJson(Map<String, dynamic> json) {
    return FootmatchMemberListItem(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      rating: (json['rating'] as num).toInt(),
    );
  }
}

class FootmatchTeamListItem {
  const FootmatchTeamListItem({
    required this.id,
    required this.teamName,
    required this.teamRating,
    required this.leaderUsername,
    required this.memberCount,
  });

  final int id;
  final String teamName;
  final int teamRating;
  final String leaderUsername;
  final int memberCount;

  factory FootmatchTeamListItem.fromJson(Map<String, dynamic> json) {
    return FootmatchTeamListItem(
      id: (json['id'] as num).toInt(),
      teamName: json['teamName'] as String,
      teamRating: (json['teamRating'] as num).toInt(),
      leaderUsername: json['leaderUsername'] as String,
      memberCount: (json['memberCount'] as num).toInt(),
    );
  }
}
