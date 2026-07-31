/// Qualitative rating gauge widget.
///
/// Displays a qualitative rating (Excellent, Great, Good, Standard,
/// Poor, Critical) as a text label. This is used for documentation
/// and test coverage ratings from Groq.
///
/// This is a placeholder implementation. During the UI polish pass,
/// replace with a proper radial dial or badge with color coding
/// based on the rating level.

import 'package:flutter/material.dart';
import '../models/scan_result.dart';

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
