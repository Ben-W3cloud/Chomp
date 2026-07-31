import '../models/repo.dart';
import '../models/scan_result.dart';
import '../models/alert.dart';
import '../models/feed_item.dart';
import 'api_client.dart';

/// Reads app data back from our backend, which is backed by Neon
/// Postgres. The client never opens a direct Postgres connection —
/// mobile apps and raw DB drivers/credentials don't mix.
class ChompDataService {
  final _api = ApiClient.instance;

  Future<List<Repo>> getRepos() async {
    final res = await _api.get('/repos') as Map<String, dynamic>;
    return (res['repos'] as List)
        .map((e) => Repo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ScanResult>> getScanHistory(String repoId,
      {int limit = 30}) async {
    final res = await _api.get('/repos/$repoId/scans?limit=$limit')
        as Map<String, dynamic>;
    return (res['scans'] as List)
        .map((e) => ScanResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ScanResult?> getLatestScan(String repoId) async {
    final history = await getScanHistory(repoId, limit: 1);
    return history.isEmpty ? null : history.first;
  }

  Future<List<ChompAlert>> getAlerts(String repoId) async {
    final res = await _api.get('/repos/$repoId/alerts') as Map<String, dynamic>;
    return (res['alerts'] as List)
        .map((e) => ChompAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FeedItem>> getFeed({int limit = 50}) async {
    final res = await _api.get('/feed?limit=$limit') as Map<String, dynamic>;
    return (res['items'] as List)
        .map((e) => FeedItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addToWatchlist(String repoId) =>
      _api.post('/repos/$repoId/watch', {});
  Future<void> removeFromWatchlist(String repoId) =>
      _api.post('/repos/$repoId/unwatch', {});
}
