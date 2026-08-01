/// Empty state — designed absence, not dead space.
///
/// Every list in the app (repos, feed, watchlist, alerts, insights)
/// gets the same guided empty state: an icon in a soft brand tile, a
/// clear line of copy, and an optional CTA. Rendered inside a
/// scrollable so pull-to-refresh keeps working on empty lists.

library;

import 'package:flutter/material.dart';
import '../core/theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 56),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Double-bezel icon tile.
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: scheme.outline),
                color: tokens.surfaceHigh.withValues(alpha: 0.6),
              ),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.brand.withValues(alpha: 0.2),
                      AppColors.brand.withValues(alpha: 0.06),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.16),
                      blurRadius: 32,
                    ),
                  ],
                ),
                child: Icon(icon, size: 40, color: AppColors.brand),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
