import 'package:flutter/material.dart';

/// Numeric 0-100 gauge for Security / Code Quality. This is a linear
/// bar placeholder — swap in a real radial dial (fl_chart or
/// syncfusion_flutter_gauges) during the UI polish pass. Kept simple
/// now so real scan scores have somewhere to render immediately.
class SpeedometerGauge extends StatelessWidget {
  const SpeedometerGauge({super.key, required this.label, required this.value});
  final String label;
  final int? value;

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
