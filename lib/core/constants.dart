class AppConstants {
  static const appName = 'Chomp';
  static const autoWatchCount = 3;
  static const maxManualWatchlist = 4;
  static const maxWatchlistTotal = autoWatchCount + maxManualWatchlist;
  static const scanIntervalHours = 1;
  static const defaultScoreDropThreshold = 10;
}

class ApiEndpoints {
  static const githubOAuthExchange = '/github/oauth/exchange';
  static const githubSyncRepos = '/github/sync-repos';
  static const scanRepo = '/scan'; // + /{repoId} — SSE stream
  static const registerDevice = '/notifications/register-device';
}
