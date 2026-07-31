enum FeedItemType { commit, pullRequest, issue, scanComplete }

/// Extension methods for [FeedItemType].
///
/// Provides conversion between enum values and string representations
/// for JSON serialization/deserialization.
extension FeedItemTypeX on FeedItemType {
  /// Creates a [FeedItemType] from a string value.
  /// Defaults to [FeedItemType.commit] if unrecognized.
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

/// Individual feed item representing user activity.
///
/// Displayed in the Feed tab of the app. Currently only populated
/// automatically for scan completions; other types require webhook
/// integration with GitHub.
class FeedItem {
  /// Unique identifier for this feed item.
  final String id;

  /// Foreign key to the repository this item is for.
  final String repoId;

  /// Type of activity this item represents.
  final FeedItemType type;

  /// Display title for this feed item.
  final String title;

  /// Optional URL to the related GitHub resource (commit, PR, issue).
  /// Null for scan_complete items.
  final String? githubUrl;

  /// Timestamp when this activity occurred.
  final DateTime createdAt;

  const FeedItem({
    required this.id,
    required this.repoId,
    required this.type,
    required this.title,
    this.githubUrl,
    required this.createdAt,
  });

  /// Creates a [FeedItem] from a JSON map returned by the backend.
  factory FeedItem.fromJson(Map<String, dynamic> json) => FeedItem(
        id: json['id'] as String,
        repoId: json['repo_id'] as String,
        type: FeedItemTypeX.fromString(json['type'] as String),
        title: json['title'] as String,
        githubUrl: json['github_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
/// Feed item model representing an activity in the user's activity feed.
///
/// Feed items can be:
/// - Scan completion notifications
/// - GitHub commits (requires webhook integration - future)
/// - Pull requests (requires webhook integration - future)
/// - Issues (requires webhook integration - future)
