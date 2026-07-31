/// Repository detail screen.
///
/// Shows detailed scan results for a single repository including:
/// - Security and code quality scores (from NVIDIA)
/// - Documentation and test ratings (from Groq)
/// - Commit heatmap (placeholder - requires backend endpoint)
/// - Scan button to trigger a new manual scan
/// - Live scan log showing phase progress
///
/// Loads the latest cached scan result on init and supports
/// triggering new scans via SSE.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/repo.dart';
import '../../providers/scan_provider.dart';
import '../../widgets/speedometer_gauge.dart';
import '../../widgets/qualitative_gauge.dart';
import '../../widgets/heatmap_strip.dart';
import '../../widgets/scan_log_view.dart';

class RepoDetailScreen extends ConsumerStatefulWidget {
  const RepoDetailScreen({super.key, required this.repo});
  final Repo repo;

  @override
  ConsumerState<RepoDetailScreen> createState() => _RepoDetailScreenState();
}

class _RepoDetailScreenState extends ConsumerState<RepoDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load the latest cached scan result for this repo
    Future.microtask(
        () => ref.read(scanProvider.notifier).loadLatest(widget.repo.id));
  }

  @override
  Widget build(BuildContext context) {
    // Get the scan state for this specific repo
    final scanState =
        ref.watch(scanProvider)[widget.repo.id] ?? const RepoScanState();
    final result = scanState.latestResult;

    return Scaffold(
      appBar: AppBar(title: Text(widget.repo.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Score gauges grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              SpeedometerGauge(label: 'Security', value: result?.securityScore),
              SpeedometerGauge(
                  label: 'Code Quality', value: result?.codeQualityScore),
              QualitativeGauge(label: 'Docs', rating: result?.docsRating),
              QualitativeGauge(label: 'Tests', rating: result?.testsRating),
            ],
          ),
          const SizedBox(height: 16),
          // Commit heatmap placeholder
          HeatmapStrip(repoId: widget.repo.id),
          const SizedBox(height: 16),
          // Repo description
          Text(widget.repo.description ?? 'No description yet.'),
          const SizedBox(height: 16),
          // Manual scan button
          FilledButton(
            onPressed: scanState.isScanning
                ? null
                : () => ref.read(scanProvider.notifier).runScan(widget.repo.id),
            child: Text(scanState.isScanning ? 'Scanning…' : 'Scan Again'),
          ),
          // Live scan log (shown during/after scan)
          if (scanState.log.isNotEmpty) ScanLogView(entries: scanState.log),
          // Error message (if scan failed)
          if (scanState.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(scanState.error!,
                  style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
}
