import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/repo.dart';
import '../services/github_service.dart';
import '../services/chomp_data_service.dart';

final githubServiceProvider = Provider((ref) => GitHubService());
final chompDataServiceProvider = Provider((ref) => ChompDataService());

class RepoState {
  final bool isLoading;
  final List<Repo> repos;
  final String? error;
  const RepoState({this.isLoading = false, this.repos = const [], this.error});

  RepoState copyWith({bool? isLoading, List<Repo>? repos, String? error}) =>
      RepoState(
        isLoading: isLoading ?? this.isLoading,
        repos: repos ?? this.repos,
        error: error,
      );

  List<Repo> get autoWatched => repos.where((r) => r.isAutoWatched).toList();
  List<Repo> get manuallyWatched =>
      repos.where((r) => r.isManuallyWatched).toList();
  List<Repo> get unwatched => repos.where((r) => !r.isWatched).toList();
  int get watchlistCount => autoWatched.length + manuallyWatched.length;
}

class RepoNotifier extends StateNotifier<RepoState> {
  RepoNotifier(this._github, this._data) : super(const RepoState());
  final GitHubService _github;
  final ChompDataService _data;

  Future<void> loadFromCache() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repos = await _data.getRepos();
      state = state.copyWith(isLoading: false, repos: repos);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> syncFromGitHub() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repos = await _github.syncRepos();
      state = state.copyWith(isLoading: false, repos: repos);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleWatch(Repo repo) async {
    if (repo.isAutoWatched) return; // auto-watched repos aren't toggleable
    try {
      if (repo.isManuallyWatched) {
        await _data.removeFromWatchlist(repo.id);
      } else {
        if (state.manuallyWatched.length >= AppConstants.maxManualWatchlist) {
          state = state.copyWith(
            error:
                'Watchlist is full (${AppConstants.maxManualWatchlist} max). Remove one first.',
          );
          return;
        }
        await _data.addToWatchlist(repo.id);
      }
      await loadFromCache();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final repoProvider = StateNotifierProvider<RepoNotifier, RepoState>(
  (ref) => RepoNotifier(
      ref.watch(githubServiceProvider), ref.watch(chompDataServiceProvider)),
);
