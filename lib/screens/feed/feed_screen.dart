/// Activity feed screen.
///
/// Displays a chronological list of user's repository activities.
/// Currently shows scan completion events. Future updates will
/// include commits, pull requests, and issues via GitHub webhooks.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/feed_provider.dart';
import '../../widgets/feed_item_tile.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the feed provider - auto-fetches when screen is visible
    final feed = ref.watch(feedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: feed.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, i) => FeedItemTile(item: items[i]),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load feed: $e')),
      ),
    );
  }
}
