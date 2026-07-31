import 'package:flutter/material.dart';
import '../models/alert.dart';

class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.alert});
  final ChompAlert alert;

  @override
  Widget build(BuildContext context) {
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
