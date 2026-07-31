/// App settings state management using Riverpod.
///
/// Manages user preferences for:
/// - Theme mode (light/dark/system)
/// - Notification settings (new issues, score drops)
/// - Score drop threshold for notifications
///
/// Currently stored in-memory only. During the UI polish pass,
/// persist these to local storage or a backend endpoint so they
/// survive app restarts.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Available theme modes for the app.
enum ThemeModePref { light, dark, system }

/// User settings state.
///
/// Contains all configurable preferences for the app.
/// Default values are provided for all settings.
class SettingsState {
  /// Preferred theme mode.
  final ThemeModePref themeMode;

  /// Whether to notify when new issues are found in scans.
  final bool notifyOnNewIssue;

  /// Whether to notify when security scores drop significantly.
  final bool notifyOnScoreDrop;

  /// Minimum score drop (in points) to trigger a notification.
  final int scoreDropThreshold;

  const SettingsState({
    this.themeMode = ThemeModePref.system,
    this.notifyOnNewIssue = true,
    this.notifyOnScoreDrop = true,
    this.scoreDropThreshold = 10,
  });

  /// Creates a copy of this state with optional field overrides.
  SettingsState copyWith({
    ThemeModePref? themeMode,
    bool? notifyOnNewIssue,
    bool? notifyOnScoreDrop,
    int? scoreDropThreshold,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        notifyOnNewIssue: notifyOnNewIssue ?? this.notifyOnNewIssue,
        notifyOnScoreDrop: notifyOnScoreDrop ?? this.notifyOnScoreDrop,
        scoreDropThreshold: scoreDropThreshold ?? this.scoreDropThreshold,
      );
}

/// Manages app settings and preferences.
///
/// Provides methods to update individual settings. All changes
/// are immediate and reflected in the UI via Riverpod.
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  /// Updates the preferred theme mode.
  void setThemeMode(ThemeModePref mode) =>
      state = state.copyWith(themeMode: mode);

  /// Updates whether to notify on new issues.
  void setNotifyOnNewIssue(bool value) =>
      state = state.copyWith(notifyOnNewIssue: value);

  /// Updates whether to notify on score drops.
  void setNotifyOnScoreDrop(bool value) =>
      state = state.copyWith(notifyOnScoreDrop: value);

  /// Updates the minimum score drop threshold for notifications.
  void setScoreDropThreshold(int value) =>
      state = state.copyWith(scoreDropThreshold: value);
}

/// Provider for the current app settings.
///
/// Use this to watch settings changes and update the UI accordingly.
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);
