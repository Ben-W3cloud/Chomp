import 'package:flutter/material.dart';
import '../models/scan_result.dart';

/// Docs / Tests gauge — same idea as SpeedometerGauge but the value is
/// one of six labels. Placeholder styling; swap for a real dial with a
/// fixed-position needle during the UI polish pass.
class QualitativeGauge extends StatelessWidget {
  const QualitativeGauge(
      {super.key, required this.label, required this.rating});
  final String label;
  final QualitativeRating? rating;

  @override
  Widget build(BuildContext context) {
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
          Text(rating?.label ?? 'Pending',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
