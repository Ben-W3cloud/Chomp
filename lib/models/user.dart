class ChompUser {
  /// Unique identifier for the user in Chomp's database.
  final String id;

  /// GitHub user ID (numeric, from GitHub's API).
  final int githubId;

  /// GitHub username/login.
  final String githubUsername;

  /// URL to the user's GitHub avatar image.
  final String? avatarUrl;

  /// Timestamp of when the user account was created.
  final DateTime createdAt;

  const ChompUser({
    required this.id,
    required this.githubId,
    required this.githubUsername,
    this.avatarUrl,
    required this.createdAt,
  });

  /// Creates a [ChompUser] from a JSON map returned by the backend.
  ///
  /// The backend returns snake_case field names which are mapped to
  /// the Dart model's camelCase properties.
  factory ChompUser.fromJson(Map<String, dynamic> json) => ChompUser(
        id: json['id'] as String,
        githubId: json['github_id'] as int,
        githubUsername: json['github_username'] as String,
        avatarUrl: json['avatar_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
