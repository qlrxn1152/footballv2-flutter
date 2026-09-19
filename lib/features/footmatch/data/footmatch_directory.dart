class FootmatchMemberListItem {
  const FootmatchMemberListItem({
    required this.username,
    required this.rating,
  });

  final String username;
  final int rating;

  factory FootmatchMemberListItem.fromJson(Map<String, dynamic> json) {
    return FootmatchMemberListItem(
      username: json['username'] as String,
      rating: (json['rating'] as num).toInt(),
    );
  }
}

class FootmatchTeamListItem {
  const FootmatchTeamListItem({
    required this.teamName,
    required this.teamRating,
    required this.leaderUsername,
    required this.memberCount,
  });

  final String teamName;
  final int teamRating;
  final String leaderUsername;
  final int memberCount;

  factory FootmatchTeamListItem.fromJson(Map<String, dynamic> json) {
    return FootmatchTeamListItem(
      teamName: json['teamName'] as String,
      teamRating: (json['teamRating'] as num).toInt(),
      leaderUsername: json['leaderUsername'] as String,
      memberCount: (json['memberCount'] as num).toInt(),
    );
  }
}
