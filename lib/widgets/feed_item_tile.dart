/// Feed item tile widget.
///
/// Displays a single activity item in the feed list. Shows an icon
/// based on the activity type, the title, and timestamp. Tapping
/// opens the related GitHub URL (if available) in a browser.
///
/// Activity types:
/// - commit: GitHub commit
/// - pullRequest: Pull request
/// - issue: GitHub issue
/// - scanComplete: Scan completion notification

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/feed_item.dart';

class FeedItemTile extends StatelessWidget {
  const FeedItemTile({super.key, required this.item});
  final FeedItem item;

  /// Returns the appropriate icon for the feed item type.
  IconData get _icon => switch (item.type) {
        FeedItemType.commit => Icons.commit,
        FeedItemType.pullRequest => Icons.merge_type,
        FeedItemType.issue => Icons.error_outline,
        FeedItemType.scanComplete => Icons.check_circle_outline,
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_icon),
      title: Text(item.title),
      subtitle: Text(item.createdAt.toLocal().toString()),
      onTap: item.githubUrl == null
          ? null
          : () => launchUrl(Uri.parse(item.githubUrl!)),
    );
  }
}
