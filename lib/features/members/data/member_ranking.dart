class MemberRanking {
  const MemberRanking({
    required this.rank,
    required this.memberId,
    required this.username,
    required this.rating,
    this.teamId,
    this.teamName,
  });

  final int rank;
  final int memberId;
  final String username;
  final int rating;
  final int? teamId;
  final String? teamName;

  factory MemberRanking.fromJson(Map<String, dynamic> json) {
    return MemberRanking(
      rank: (json['rank'] as num).toInt(),
      memberId: (json['memberId'] as num).toInt(),
      username: json['username'] as String,
      rating: (json['rating'] as num).toInt(),
      teamId: (json['teamId'] as num?)?.toInt(),
      teamName: json['teamName'] as String?,
    );
  }
}
