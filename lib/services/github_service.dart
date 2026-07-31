import '../core/constants.dart';
import '../models/repo.dart';
import 'api_client.dart';

/// Talks to OUR backend only — never to api.github.com directly. The
/// phone never holds the user's GitHub access token.
class GitHubService {
  final _api = ApiClient.instance;

  /// Tells the backend to pull the latest repo list from GitHub for
  /// this user, upsert it into Neon, and return the result. Call on
  /// app open and on pull-to-refresh.
  Future<List<Repo>> syncRepos() async {
    final response = await _api.post(ApiEndpoints.githubSyncRepos, {})
        as Map<String, dynamic>;
    final list = response['repos'] as List<dynamic>;
    return list.map((e) => Repo.fromJson(e as Map<String, dynamic>)).toList();
  }
}
