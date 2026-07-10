class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.expiresAt,
    required this.memberId,
    required this.username,
    required this.memberRating,
  });

  final String accessToken;
  final String tokenType;
  final DateTime expiresAt;
  final int memberId;
  final String username;
  final int memberRating;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory AuthSession.fromLoginJson(Map<String, dynamic> json) {
    final expiresIn = (json['expiresIn'] as num?)?.toInt() ?? 3600;

    return AuthSession(
      accessToken: json['accessToken'] as String,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      memberId: (json['memberId'] as num).toInt(),
      username: json['username'] as String,
      memberRating: (json['memberRating'] as num).toInt(),
    );
  }
}
