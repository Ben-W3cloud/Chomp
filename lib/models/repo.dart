class Repo {
  final String id;
  final int githubRepoId;
  final String name;
  final String fullName;
  final String? description;
  final String? language;
  final String defaultBranch;
  final bool isAutoWatched;
  final bool isManuallyWatched;
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

  bool get isWatched => isAutoWatched || isManuallyWatched;

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
