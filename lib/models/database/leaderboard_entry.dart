class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.score,
    required this.title,
    required this.rank,
  });

  final String userId;
  final String username;
  final String displayName;
  final int score;
  final String title;
  final int rank;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] as String,
      username: (json['username'] as String?) ?? '',
      displayName: (json['display_name'] as String?) ??
          (json['username'] as String?) ??
          'Agent',
      score: (json['score'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? 'Rookie',
      rank: (json['rank'] as num?)?.toInt() ?? 0,
    );
  }
}
