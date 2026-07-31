/// GitHub repository synchronization service.
///
/// This service communicates with our backend to sync the user's
/// GitHub repositories. The client never calls GitHub's API directly —
/// all GitHub interactions happen server-side to protect the user's
/// access token.
///
/// Call [syncRepos] on app startup and during pull-to-refresh to
/// keep the local repo list up to date.

import '../core/constants.dart';
import '../models/repo.dart';
import 'api_client.dart';

/// Service for syncing GitHub repositories via the backend.
///
/// The backend handles the actual GitHub API calls using the user's
/// encrypted access token, then returns the repo list to the client.
class GitHubService {
  final _api = ApiClient.instance;

  /// Fetches the latest repository list from GitHub and updates the
  /// backend database.
  ///
  /// This triggers the backend to:
  /// 1. Decrypt the user's GitHub access token
  /// 2. Call GitHub's /user/repos API
  /// 3. Upsert each repo into Neon with auto-watch flags
  /// 4. Return the updated repo list
  ///
  /// Call this on app open and on pull-to-refresh.
  Future<List<Repo>> syncRepos() async {
    final response = await _api.post(ApiEndpoints.githubSyncRepos, {})
        as Map<String, dynamic>;
    final list = response['repos'] as List<dynamic>;
    return list.map((e) => Repo.fromJson(e as Map<String, dynamic>)).toList();
  }
}
