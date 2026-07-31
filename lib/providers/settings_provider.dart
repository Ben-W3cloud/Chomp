import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ThemeModePref { light, dark, system }

class SettingsState {
  final ThemeModePref themeMode;
  final bool notifyOnNewIssue;
  final bool notifyOnScoreDrop;
  final int scoreDropThreshold;

  const SettingsState({
    this.themeMode = ThemeModePref.system,
    this.notifyOnNewIssue = true,
    this.notifyOnScoreDrop = true,
    this.scoreDropThreshold = 10,
  });

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

/// In-memory only for now — wire this up to a `/settings` backend
/// endpoint (or local storage) during the UI polish pass so
/// preferences survive an app restart.
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void setThemeMode(ThemeModePref mode) =>
      state = state.copyWith(themeMode: mode);
  void setNotifyOnNewIssue(bool value) =>
      state = state.copyWith(notifyOnNewIssue: value);
  void setNotifyOnScoreDrop(bool value) =>
      state = state.copyWith(notifyOnScoreDrop: value);
  void setScoreDropThreshold(int value) =>
      state = state.copyWith(scoreDropThreshold: value);
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);
