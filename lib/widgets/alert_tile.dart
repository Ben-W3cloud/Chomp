/// Alert tile widget.
///
/// Displays a single alert/notification in a list tile format.
/// Shows the alert message with a color-coded icon based on severity:
/// - Red for critical alerts
/// - Amber for warnings
/// - Blue for info
///
/// Used in the repo detail screen to show scan findings and
/// security issues.

import 'package:flutter/material.dart';
import '../models/alert.dart';

class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.alert});
  final ChompAlert alert;

  @override
  Widget build(BuildContext context) {
    // Determine icon color based on alert severity
    final color = switch (alert.severity) {
      AlertSeverity.critical => Colors.red,
      AlertSeverity.warning => Colors.amber,
      AlertSeverity.info => Colors.blue,
    };

    return ListTile(
      leading: Icon(Icons.warning_amber_rounded, color: color),
      title: Text(alert.message),
    );
  }
}
