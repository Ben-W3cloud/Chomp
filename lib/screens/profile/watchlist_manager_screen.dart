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
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Auto-watched (3 most recently active)',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final repo in repoState.autoWatched)
            ListTile(title: Text(repo.name), trailing: const Icon(Icons.bolt)),
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
