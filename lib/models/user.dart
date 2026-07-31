class ChompUser {
  final String id;
  final int githubId;
  final String githubUsername;
  final String? avatarUrl;
  final DateTime createdAt;

  const ChompUser({
    required this.id,
    required this.githubId,
    required this.githubUsername,
    this.avatarUrl,
    required this.createdAt,
  });

  factory ChompUser.fromJson(Map<String, dynamic> json) => ChompUser(
        id: json['id'] as String,
        githubId: json['github_id'] as int,
        githubUsername: json['github_username'] as String,
        avatarUrl: json['avatar_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
