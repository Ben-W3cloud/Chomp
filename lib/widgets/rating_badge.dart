/// Rating badge — qualitative Docs/Tests ratings from Groq.
///
/// A soft tinted pill: colored dot, rating label, thin hairline shell.
/// Each rating level maps to a distinct hue so the grid reads at a
/// glance without relying on words.

library;

import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/scan_result.dart';

class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.label, required this.rating});

  final String label;
  final QualitativeRating? rating;

  Color _color(QualitativeRating r) => switch (r) {
        QualitativeRating.excellent => const Color(0xFF22C55E),
        QualitativeRating.great => const Color(0xFF4ADE80),
        QualitativeRating.good => const Color(0xFFA3E635),
        QualitativeRating.standard => AppColors.warning,
        QualitativeRating.poor => const Color(0xFFFB923C),
        QualitativeRating.critical => AppColors.danger,
      };

  IconData _icon(QualitativeRating r) => switch (r) {
        QualitativeRating.excellent => Icons.bolt_rounded,
        QualitativeRating.great => Icons.trending_up_rounded,
        QualitativeRating.good => Icons.check_circle_outline,
        QualitativeRating.standard => Icons.remove_rounded,
        QualitativeRating.poor => Icons.warning_amber_rounded,
        QualitativeRating.critical => Icons.dangerous_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final r = rating;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.shell),
        border: Border.all(color: scheme.outline),
        color: tokens.surfaceHigh.withValues(alpha: 0.5),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          color: tokens.surface,
        ),
        child: Row(
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
            ),
            const Spacer(),
            if (r == null)
              Text('—', style: Theme.of(context).textTheme.titleMedium)
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  color: _color(r).withValues(alpha: 0.14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_icon(r), size: 14, color: _color(r)),
                    const SizedBox(width: 6),
                    Text(
                      r.label,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: _color(r)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
