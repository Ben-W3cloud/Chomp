/// Repo detail — the payoff screen.
///
/// Hero pair of radial gauges (Security / Code Quality) sweeping in on
/// entry, Docs / Tests as rating badges, an alerts panel with a guided
/// empty state, commit activity placeholder, and the live animated
/// scan log under a full-width scan button.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/repo.dart';
import '../../providers/scan_provider.dart';
import '../../providers/repo_provider.dart';
import '../../widgets/alert_tile.dart';
import '../../widgets/heatmap_strip.dart';
import '../../widgets/radial_gauge.dart';
import '../../widgets/rating_badge.dart';
import '../../widgets/reveal.dart';
import '../../widgets/scan_log_view.dart';

final _alertsProvider =
    FutureProvider.autoDispose.family((ref, String repoId) async {
  final data = ref.watch(chompDataServiceProvider);
  return data.getAlerts(repoId);
});

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
    final alerts = ref.watch(_alertsProvider(widget.repo.id));

    return Scaffold(
      appBar: AppBar(title: Text(widget.repo.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // Hero gauges.
          Row(
            children: [
              Expanded(
                child: Reveal(
                  delayMs: 40,
                  child: RadialGauge(
                      label: 'SECURITY', value: result?.securityScore),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Reveal(
                  delayMs: 130,
                  child: RadialGauge(
                      label: 'CODE QUALITY', value: result?.codeQualityScore),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Qualitative ratings.
          Reveal(
            delayMs: 220,
            child: Column(
              children: [
                RatingBadge(label: 'Docs', rating: result?.docsRating),
                const SizedBox(height: 12),
                RatingBadge(label: 'Tests', rating: result?.testsRating),
              ],
            ),
          ),
          // Commit activity placeholder.
          Reveal(delayMs: 300, child: HeatmapStrip(repoId: widget.repo.id)),
          // Description.
          Reveal(
            delayMs: 360,
            child: Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border:
                    Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Text(
                widget.repo.description ?? 'No description yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
            ),
          ),
          // Alerts.
          Reveal(delayMs: 420, child: _AlertsSection(alerts: alerts)),
          const SizedBox(height: 28),
          // Scan action.
          _ScanButton(
              scanning: scanState.isScanning,
              onPressed: () {
                ref.read(scanProvider.notifier).runScan(widget.repo.id);
              }),
          if (scanState.log.isNotEmpty)
            Reveal(delayMs: 100, child: ScanLogView(entries: scanState.log)),
          if (scanState.error != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border:
                    Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_rounded,
                      size: 18, color: AppColors.danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      scanState.error!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.danger),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    color: AppColors.danger,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => ref
                        .read(scanProvider.notifier)
                        .dismissError(widget.repo.id),
                    tooltip: 'Dismiss',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AlertsSection extends StatelessWidget {
  const _AlertsSection({required this.alerts});

  final AsyncValue alerts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget body = alerts.when(
      loading: () => const SizedBox(
        height: 64,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Could not load alerts.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.5)),
        ),
      ),
      data: (items) => items.isEmpty
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card),
                color: Theme.of(context).cardTheme.color,
                border: Border.all(color: scheme.outline),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: AppColors.success.withValues(alpha: 0.8),
                      size: 26),
                  const SizedBox(height: 8),
                  Text(
                    'All quiet there are no alerts',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'New findings and score drops will land here.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                for (final alert in items) ...[
                  AlertTile(alert: alert),
                  const SizedBox(height: 8),
                ],
              ],
            ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 28, bottom: 12),
          child: Text(
            'ALERTS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        body,
      ],
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.scanning, required this.onPressed});

  final bool scanning;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: scanning ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill)),
      ),
      child: AnimatedSwitcher(
        duration: AppMotion.micro,
        switchInCurve: AppMotion.curve,
        switchOutCurve: AppMotion.curve,
        child: scanning
            ? const Row(
                key: ValueKey('scanning'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Text('Scanning'),
                ],
              )
            : const Row(
                key: ValueKey('idle'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.radar_rounded, size: 18),
                  SizedBox(width: 10),
                  Text('Scan Again'),
                ],
              ),
      ),
    );
  }
}
