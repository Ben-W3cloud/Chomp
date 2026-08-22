/// Tiny time helpers.

library;

import 'package:intl/intl.dart';

/// Compact relative time: "now", "5m", "2h", "3d", "6w", else "d MMM".
String relativeTime(DateTime dt) {
  final local = dt.toLocal();
  final diff = DateTime.now().difference(local);
  if (diff.inSeconds < 60) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  if (diff.inDays < 30) return '${diff.inDays ~/ 7}w';
  return DateFormat('d MMM').format(local);
}
