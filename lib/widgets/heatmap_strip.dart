import 'package:flutter/material.dart';

/// Placeholder — will fetch commit history via the backend and render
/// a real 30-day heatmap + streak counter during the UI polish pass.
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
