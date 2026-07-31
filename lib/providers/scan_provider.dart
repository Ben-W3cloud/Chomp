import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scan_result.dart';
import '../services/scan_engine.dart';
import '../services/chomp_data_service.dart';
import 'repo_provider.dart';

final scanEngineProvider = Provider((ref) => ScanEngine());

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

class ScanNotifier extends StateNotifier<Map<String, RepoScanState>> {
  ScanNotifier(this._engine, this._data) : super({});
  final ScanEngine _engine;
  final ChompDataService _data;

  RepoScanState stateFor(String repoId) =>
      state[repoId] ?? const RepoScanState();

  Future<void> loadLatest(String repoId) async {
    final latest = await _data.getLatestScan(repoId);
    _update(repoId, stateFor(repoId).copyWith(latestResult: latest));
  }

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
        if (current.isScanning)
          _update(repoId, current.copyWith(isScanning: false));
      },
    );
  }

  void _update(String repoId, RepoScanState value) {
    state = {...state, repoId: value};
  }
}

final scanProvider =
    StateNotifierProvider<ScanNotifier, Map<String, RepoScanState>>(
  (ref) => ScanNotifier(
      ref.watch(scanEngineProvider), ref.watch(chompDataServiceProvider)),
);
