enum FeedItemType { commit, pullRequest, issue, scanComplete }

extension FeedItemTypeX on FeedItemType {
  static FeedItemType fromString(String value) {
    switch (value) {
      case 'commit':
        return FeedItemType.commit;
      case 'pr':
        return FeedItemType.pullRequest;
      case 'issue':
        return FeedItemType.issue;
      case 'scan_complete':
        return FeedItemType.scanComplete;
      default:
        return FeedItemType.commit;
    }
  }
}

class FeedItem {
  final String id;
  final String repoId;
  final FeedItemType type;
  final String title;
  final String? githubUrl;
  final DateTime createdAt;

  const FeedItem({
    required this.id,
    required this.repoId,
    required this.type,
    required this.title,
    this.githubUrl,
    required this.createdAt,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) => FeedItem(
        id: json['id'] as String,
        repoId: json['repo_id'] as String,
        type: FeedItemTypeX.fromString(json['type'] as String),
        title: json['title'] as String,
        githubUrl: json['github_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
