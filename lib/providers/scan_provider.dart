/// Scan state management using Riverpod.
///
/// Manages the state of repository scans including:
/// - Running manual scans via SSE
/// - Tracking scan progress and phase logs
/// - Storing the latest scan results per repository
/// - Handling scan errors
///
/// Each repository has its own [RepoScanState] tracked in a map,
/// allowing multiple repos to be scanned independently.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scan_result.dart';
import '../services/scan_engine.dart';
import '../services/chomp_data_service.dart';
import 'repo_provider.dart';

/// Provider for the [ScanEngine] instance.
final scanEngineProvider = Provider((ref) => ScanEngine());

/// State for a single repository's scan.
///
/// Tracks whether a scan is in progress, the phase log entries,
/// the latest scan result, and any errors that occurred.
class RepoScanState {
  final bool isScanning;
  final List<ScanPhaseEvent> log;
  final ScanResult? latestResult;
  final String? error;

  const RepoScanState(
      {this.isScanning = false,
      this.log = const [],
      this.latestResult,
      this.error});

  /// Creates a copy of this state with optional field overrides.
  RepoScanState copyWith({
    bool? isScanning,
    List<ScanPhaseEvent>? log,
    ScanResult? latestResult,
    String? error,
  }) =>
      RepoScanState(
        isScanning: isScanning ?? this.isScanning,
        log: log ?? this.log,
        latestResult: latestResult ?? this.latestResult,
        error: error,
      );
}

/// Manages scan state for all repositories.
///
/// Coordinates between [ScanEngine] (which runs the scan via SSE)
/// and [ChompDataService] (which fetches cached scan results).
/// Each repo's state is stored in a map keyed by repo ID.
class ScanNotifier extends StateNotifier<Map<String, RepoScanState>> {
  ScanNotifier(this._engine, this._data) : super({});
  final ScanEngine _engine;
  final ChompDataService _data;

  /// Gets the scan state for a specific repository.
  ///
  /// Returns an empty [RepoScanState] if the repo hasn't been scanned yet.
  RepoScanState stateFor(String repoId) =>
      state[repoId] ?? const RepoScanState();

  /// Loads the latest cached scan result for a repository.
  ///
  /// Fetches from the backend without triggering a new scan.
  /// Used when navigating to the repo detail screen.
  Future<void> loadLatest(String repoId) async {
    final latest = await _data.getLatestScan(repoId);
    _update(repoId, stateFor(repoId).copyWith(latestResult: latest));
  }

  /// Initiates a manual scan for a repository.
  ///
  /// Opens an SSE connection to the backend and streams phase events
  /// into the log. When the scan completes, updates the state with
  /// the final result. Clears the previous log and result.
  Future<void> runScan(String repoId) async {
    _update(repoId, const RepoScanState(isScanning: true, log: []));
    _engine.runScan(repoId).listen(
      (event) {
        final current = stateFor(repoId);
        var next = current.copyWith(log: [...current.log, event]);
        if (event.phase == ScanPhase.complete && event.payload != null) {
          next = next.copyWith(
              isScanning: false,
              latestResult: ScanResult.fromJson(event.payload!));
        }
        if (event.phase == ScanPhase.error) {
          next = next.copyWith(isScanning: false, error: event.message);
        }
        _update(repoId, next);
      },
      onDone: () {
        final current = stateFor(repoId);
        if (current.isScanning) {
          _update(repoId, current.copyWith(isScanning: false));
        }
      },
    );
  }

  /// Updates the state for a specific repository.
  void _update(String repoId, RepoScanState value) {
    state = {...state, repoId: value};
  }
}

/// Provider for the scan state map.
///
/// Use this to watch scan progress for a specific repo:
/// `ref.watch(scanProvider)[repoId]`
final scanProvider =
    StateNotifierProvider<ScanNotifier, Map<String, RepoScanState>>(
  (ref) => ScanNotifier(
      ref.watch(scanEngineProvider), ref.watch(chompDataServiceProvider)),
);
