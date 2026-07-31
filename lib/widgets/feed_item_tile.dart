import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/feed_item.dart';

class FeedItemTile extends StatelessWidget {
  const FeedItemTile({super.key, required this.item});
  final FeedItem item;

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
