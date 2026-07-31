/// Repository state management using Riverpod.
///
/// Manages the user's repository list and watchlist operations:
/// - Loading repos from cache (local database via backend)
/// - Syncing repos from GitHub
/// - Adding/removing repos from the manual watchlist
/// - Tracking auto-watched vs manually-watched repos
///
/// Auto-watched repos (top 3 most recently active) are managed by
/// the backend during sync. Manual watchlist additions are limited
/// to 4 repos per user.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/repo.dart';
import '../services/github_service.dart';
import '../services/chomp_data_service.dart';

/// Provider for the [GitHubService] instance.
final githubServiceProvider = Provider((ref) => GitHubService());

/// Provider for the [ChompDataService] instance.
final chompDataServiceProvider = Provider((ref) => ChompDataService());

/// State for the user's repository list.
///
/// Contains the full list of repos, loading state, and error info.
/// Also provides computed properties for filtered views (auto-watched,
/// manually-watched, unwatched).
class RepoState {
  final bool isLoading;
  final List<Repo> repos;
  final String? error;

  const RepoState({this.isLoading = false, this.repos = const [], this.error});

  /// Creates a copy of this state with optional field overrides.
  RepoState copyWith({bool? isLoading, List<Repo>? repos, String? error}) =>
      RepoState(
        isLoading: isLoading ?? this.isLoading,
        repos: repos ?? this.repos,
        error: error,
      );

  /// Repos automatically added to the watchlist (top 3 most active).
  List<Repo> get autoWatched => repos.where((r) => r.isAutoWatched).toList();

  /// Repos manually added to the watchlist by the user.
  List<Repo> get manuallyWatched =>
      repos.where((r) => r.isManuallyWatched).toList();

  /// Repos not currently being watched.
  List<Repo> get unwatched => repos.where((r) => !r.isWatched).toList();

  /// Total number of watched repos (auto + manual).
  int get watchlistCount => autoWatched.length + manuallyWatched.length;
}

/// Manages repository state and operations.
///
/// Handles loading repos from cache, syncing with GitHub, and
/// managing the watchlist. Uses both [GitHubService] for sync
/// and [ChompDataService] for local data access.
class RepoNotifier extends StateNotifier<RepoState> {
  RepoNotifier(this._github, this._data) : super(const RepoState());
  final GitHubService _github;
  final ChompDataService _data;

  /// Loads repos from the local cache (backend database).
  ///
  /// Used on app startup to show repos immediately while syncing
  /// with GitHub in the background.
  Future<void> loadFromCache() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repos = await _data.getRepos();
      state = state.copyWith(isLoading: false, repos: repos);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Syncs repos from GitHub via the backend.
  ///
  /// Fetches the latest repo list from GitHub, updates the backend
  /// database, and returns the updated list. Call this on app open
  /// and during pull-to-refresh.
  Future<void> syncFromGitHub() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repos = await _github.syncRepos();
      state = state.copyWith(isLoading: false, repos: repos);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Toggles a repository's watch status.
  ///
  /// If the repo is auto-watched, this is a no-op (auto-watched repos
  /// can't be manually toggled). Otherwise, adds or removes the repo
  /// from the manual watchlist, enforcing the maximum limit.
  Future<void> toggleWatch(Repo repo) async {
    if (repo.isAutoWatched) return; // auto-watched repos aren't toggleable
    try {
      if (repo.isManuallyWatched) {
        await _data.removeFromWatchlist(repo.id);
      } else {
        // Enforce maximum manual watchlist size
        if (state.manuallyWatched.length >= AppConstants.maxManualWatchlist) {
          state = state.copyWith(
            error:
                'Watchlist is full (${AppConstants.maxManualWatchlist} max). Remove one first.',
          );
          return;
        }
        await _data.addToWatchlist(repo.id);
      }
      // Reload from cache to get updated watch status
      await loadFromCache();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Provider for the current repository state.
///
/// Use this to watch the repo list and trigger operations like
/// sync and watchlist management.
final repoProvider = StateNotifierProvider<RepoNotifier, RepoState>(
  (ref) => RepoNotifier(
      ref.watch(githubServiceProvider), ref.watch(chompDataServiceProvider)),
);
