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
    Future.microtask(
        () => ref.read(scanProvider.notifier).loadLatest(widget.repo.id));
  }

  @override
  Widget build(BuildContext context) {
    final scanState =
        ref.watch(scanProvider)[widget.repo.id] ?? const RepoScanState();
    final result = scanState.latestResult;

    return Scaffold(
      appBar: AppBar(title: Text(widget.repo.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          HeatmapStrip(repoId: widget.repo.id),
          const SizedBox(height: 16),
          Text(widget.repo.description ?? 'No description yet.'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: scanState.isScanning
                ? null
                : () => ref.read(scanProvider.notifier).runScan(widget.repo.id),
            child: Text(scanState.isScanning ? 'Scanning…' : 'Scan Again'),
          ),
          if (scanState.log.isNotEmpty) ScanLogView(entries: scanState.log),
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
