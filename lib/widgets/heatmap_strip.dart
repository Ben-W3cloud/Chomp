/// Commit activity card.
///
/// The backend currently discards commit history (fetchCommits is a
/// no-op), so this renders a designed placeholder rather than a fake
/// graph. A row of dim squares hints at the eventual GitHub-style
/// contribution strip. Wires in once an endpoint serves commit data.

library;

import 'package:flutter/material.dart';
import '../core/theme.dart';

class HeatmapStrip extends StatelessWidget {
  const HeatmapStrip({super.key, required this.repoId});

  final String repoId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.shell),
        border: Border.all(color: scheme.outline),
        color: tokens.surfaceHigh.withValues(alpha: 0.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          color: tokens.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COMMIT ACTIVITY',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                24,
                (i) => Expanded(
                  child: Container(
                    height: 14,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: AppColors.brand.withValues(
                          alpha: (0.05 + (i % 5) * 0.05).clamp(0, 0.3)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Coming with the commit history endpoint',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.4),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
