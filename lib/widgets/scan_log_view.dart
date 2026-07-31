/// Scan log viewer widget.
///
/// Displays a live terminal-style log of scan phase events.
/// Shows each phase as a colored line with a bullet point, creating
/// a real-time feed of the scan progress.
///
/// Used in the repo detail screen during and after manual scans.

import 'package:flutter/material.dart';
import '../services/scan_engine.dart';

class ScanLogView extends StatelessWidget {
  const ScanLogView({super.key, required this.entries});
  final List<ScanPhaseEvent> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.black87, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: entries
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '● ${e.message}',
                    style: const TextStyle(
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                        fontSize: 12),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
