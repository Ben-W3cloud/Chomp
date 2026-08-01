/// Feed item tile.
///
/// A tinted icon tile per activity type, title, and compact relative
/// time. Tapping opens the GitHub link when present. Scan completions
/// carry a subtle magenta treatment as the brand beat of the feed.

library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../models/feed_item.dart';
import '../utils/time.dart';

class FeedItemTile extends StatelessWidget {
  const FeedItemTile({super.key, required this.item});

  final FeedItem item;

  ({IconData icon, Color color, Color? tint}) get _style => switch (item.type) {
        FeedItemType.commit => (
            icon: Icons.commit_rounded,
            color: AppColors.info,
            tint: null
          ),
        FeedItemType.pullRequest => (
            icon: Icons.merge_rounded,
            color: const Color(0xFFA78BFA),
            tint: null
          ),
        FeedItemType.issue => (
            icon: Icons.error_outline_rounded,
            color: AppColors.warning,
            tint: null
          ),
        FeedItemType.scanComplete => (
            icon: Icons.bolt_rounded,
            color: AppColors.brand,
            tint: AppColors.brand
          ),
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final style = _style;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.shell),
        border: Border.all(color: scheme.outline),
        color: style.tint != null
            ? style.tint!.withValues(alpha: 0.06)
            : tokens.surfaceHigh.withValues(alpha: 0.5),
      ),
      child: Material(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: item.githubUrl == null
              ? null
              : () => launchUrl(Uri.parse(item.githubUrl!),
                  mode: LaunchMode.externalApplication),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: style.color.withValues(alpha: 0.13),
                  ),
                  alignment: Alignment.center,
                  child: Icon(style.icon, size: 20, color: style.color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        relativeTime(item.createdAt),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.4),
                            ),
                      ),
                    ],
                  ),
                ),
                if (item.githubUrl != null)
                  Icon(Icons.chevron_right_rounded,
                      color: scheme.onSurface.withValues(alpha: 0.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
