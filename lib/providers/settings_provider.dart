/// App settings state management using Riverpod.
///
/// Manages user preferences for:
/// - Theme mode (light/dark/system)
/// - Notification settings (new issues, score drops)
/// - Score drop threshold for notifications
///
/// Theme mode persists to local storage. Notification preferences
/// remain in-memory until a `/settings` backend endpoint exists.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available theme modes for the app.
enum ThemeModePref { light, dark, system }

/// User settings state.
///
/// Contains all configurable preferences for the app.
/// Default values are provided for all settings.
class SettingsState {
  /// Preferred theme mode. Defaults to dark — the brand identity.
  final ThemeModePref themeMode;

  /// Whether to notify when new issues are found in scans.
  final bool notifyOnNewIssue;

  /// Whether to notify when security scores drop significantly.
  final bool notifyOnScoreDrop;

  /// Minimum score drop (in points) to trigger a notification.
  final int scoreDropThreshold;

  const SettingsState({
    this.themeMode = ThemeModePref.dark,
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
/// are immediate and reflected in the UI via Riverpod. Theme mode
/// is persisted so it survives app restarts.
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  static const _themeKey = 'theme_mode';

  /// Loads persisted settings. Call once before `runApp` so the first
  /// frame renders with the user's chosen theme.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_themeKey);
    final mode = ThemeModePref.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => ThemeModePref.dark,
    );
    state = state.copyWith(themeMode: mode);
  }

  /// Updates the preferred theme mode and persists it.
  Future<void> setThemeMode(ThemeModePref mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

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
