class Repo {
  /// Unique identifier for the repo in Chomp's database.
  final String id;

  /// GitHub's numeric repository ID.
  final int githubRepoId;

  /// Repository name (e.g., 'my-app').
  final String name;

  /// Full repository name including owner (e.g., 'octocat/my-app').
  final String fullName;

  /// Optional repository description from GitHub.
  final String? description;

  /// Primary programming language (e.g., 'Dart', 'TypeScript').
  final String? language;

  /// Default branch name (usually 'main' or 'master').
  final String defaultBranch;

  /// Whether this repo is in the auto-watch list (top 3 most active).
  final bool isAutoWatched;

  /// Whether this repo is manually added to the watchlist by the user.
  final bool isManuallyWatched;

  /// Timestamp of the last push to any branch on GitHub.
  final DateTime? lastPushedAt;

  const Repo({
    required this.id,
    required this.githubRepoId,
    required this.name,
    required this.fullName,
    this.description,
    this.language,
    this.defaultBranch = 'main',
    this.isAutoWatched = false,
    this.isManuallyWatched = false,
    this.lastPushedAt,
  });

  /// Whether this repo is being watched (auto or manual).
  bool get isWatched => isAutoWatched || isManuallyWatched;

  /// Creates a [Repo] from a JSON map returned by the backend.
  ///
  /// Handles null values for optional fields and parses date strings
  /// into [DateTime] objects.
  factory Repo.fromJson(Map<String, dynamic> json) => Repo(
        id: json['id'] as String,
        githubRepoId: json['github_repo_id'] as int,
        name: json['name'] as String,
        fullName: json['full_name'] as String,
        description: json['description'] as String?,
        language: json['language'] as String?,
        defaultBranch: json['default_branch'] as String? ?? 'main',
        isAutoWatched: json['is_auto_watched'] as bool? ?? false,
        isManuallyWatched: json['is_manually_watched'] as bool? ?? false,
        lastPushedAt: json['last_pushed_at'] != null
            ? DateTime.parse(json['last_pushed_at'] as String)
            : null,
      );
}
