/// Alert tile — a finding from a scan.
///
/// Severity reads through a tinted icon chip: critical = red,
/// warning = amber, info = blue. Resolved alerts dim to a ghost state.

library;

import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/alert.dart';
import '../utils/time.dart';

class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.alert});

  final ChompAlert alert;

  ({IconData icon, Color color}) get _style => switch (alert.severity) {
        AlertSeverity.critical => (
            icon: Icons.dangerous_rounded,
            color: AppColors.danger
          ),
        AlertSeverity.warning => (
            icon: Icons.warning_amber_rounded,
            color: AppColors.warning
          ),
        AlertSeverity.info => (icon: Icons.info_rounded, color: AppColors.info),
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = _style;
    final dimmed = alert.resolved;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: style.color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            style.icon,
            size: 20,
            color:
                dimmed ? scheme.onSurface.withValues(alpha: 0.25) : style.color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alert.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: dimmed
                        ? scheme.onSurface.withValues(alpha: 0.35)
                        : scheme.onSurface.withValues(alpha: 0.85),
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            relativeTime(alert.createdAt),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.35),
                ),
          ),
        ],
      ),
    );
  }
}
