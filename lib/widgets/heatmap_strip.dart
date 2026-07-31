/// Commit heatmap strip widget.
///
/// Placeholder for a 30-day commit activity heatmap visualization.
/// Will display commit frequency as colored squares similar to
/// GitHub's contribution graph.
///
/// Requires a backend endpoint to fetch commit history data.
/// During the UI polish pass, implement the actual heatmap using
/// the commit data from the backend.

import 'package:flutter/material.dart';

class HeatmapStrip extends StatelessWidget {
  const HeatmapStrip({super.key, required this.repoId});
  final String repoId;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 40,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('Commit heatmap — coming in the UI pass',
            style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
