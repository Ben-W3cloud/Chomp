/// Watchlist management screen.
///
/// Displays the user's watchlist organized into three sections:
/// - Auto-watched: Top 3 most recently active repos (managed by backend)
/// - Manually watched: Repos added by the user (max 4)
/// - Other repos: Available to add to watchlist
///
/// Users can add/remove repos from their manual watchlist here.
/// Auto-watched repos cannot be removed (they're managed by the backend).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../providers/repo_provider.dart';

class WatchlistManagerScreen extends ConsumerWidget {
  const WatchlistManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoState = ref.watch(repoProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Watchlist (${repoState.watchlistCount}/${AppConstants.maxWatchlistTotal})'),
      ),
      body: ListView(
        children: [
          // Auto-watched section (top 3 most active repos)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Auto-watched (3 most recently active)',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final repo in repoState.autoWatched)
            ListTile(title: Text(repo.name), trailing: const Icon(Icons.bolt)),
          // Manually watched section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Manually watched',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final repo in repoState.manuallyWatched)
            ListTile(
              title: Text(repo.name),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () =>
                    ref.read(repoProvider.notifier).toggleWatch(repo),
              ),
            ),
          // Other repos section (available to add)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Other repos',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final repo in repoState.unwatched)
            ListTile(
              title: Text(repo.name),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () =>
                    ref.read(repoProvider.notifier).toggleWatch(repo),
              ),
            ),
        ],
      ),
    );
  }
}
