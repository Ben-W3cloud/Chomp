/// Numeric score gauge widget.
///
/// Displays a numeric score (0-100) as a linear progress bar with
/// color coding:
/// - Red: 0-40 (poor)
/// - Amber: 41-70 (standard)
/// - Green: 71-100 (good)
///
/// This is a placeholder implementation. During the UI polish pass,
/// replace with a proper radial dial using fl_chart or
/// syncfusion_flutter_gauges for a more polished look.

import 'package:flutter/material.dart';

class SpeedometerGauge extends StatelessWidget {
  const SpeedometerGauge({super.key, required this.label, required this.value});
  final String label;
  final int? value;

  /// Determines the color based on the score value.
  Color _color(int v) {
    if (v <= 40) return Colors.red;
    if (v <= 70) return Colors.amber;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final v = value;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(v == null ? '—' : '$v',
              style:
                  const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: v == null ? 0 : v / 100,
              color: v == null ? Colors.grey : _color(v),
              backgroundColor: Colors.grey.shade200,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
