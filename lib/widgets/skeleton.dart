/// Skeleton shimmer primitives for loading states.
///
/// A soft sweep of light travels across placeholder boxes — reads as
/// "content is on its way", not "app is stuck". GPU-cheap: only a
/// repainted gradient, no layout animation.

library;

import 'package:flutter/material.dart';
import '../core/theme.dart';

/// A single shimmering placeholder block.
class Skeleton extends StatefulWidget {
  const Skeleton(
      {super.key, this.width, this.height = 16, this.radius = AppRadius.sm});

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurface;
    final high = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.045);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.8 + 3.6 * t, 0),
              end: Alignment(-0.8 + 3.6 * t, 0),
              colors: [base, high, base],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton for the repo list — mirrors the real card layout.
class RepoCardSkeleton extends StatelessWidget {
  const RepoCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: const Row(
        children: [
          Skeleton(width: 44, height: 44, radius: 14),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 140, height: 16),
                SizedBox(height: 8),
                Skeleton(height: 12),
                SizedBox(height: 8),
                Skeleton(width: 90, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for the activity feed list.
class FeedTileSkeleton extends StatelessWidget {
  const FeedTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: const Row(
        children: [
          Skeleton(width: 40, height: 40, radius: 12),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 180, height: 14),
                SizedBox(height: 8),
                Skeleton(width: 90, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
