/// Server-side application constants.
///
/// Configuration values used throughout the backend. These mirror
/// the client-side AppConstants in lib/core/constants.dart but
/// include server-specific values like API keys and thresholds.

/// Maximum number of repos to auto-watch per user (top N most active).
export const AUTO_WATCH_COUNT = 3;

/// Maximum number of repos a user can manually add to their watchlist.
export const MAX_MANUAL_WATCHLIST = 4;

/// Security score drop threshold that triggers a notification.
/// If a repo's security score drops by this many points or more
/// between scans, the user receives a push notification.
export const SCORE_DROP_NOTIFY_THRESHOLD = 10;