import 'package:flutter/material.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Weekly AI summary goes here.\n\n'
            'Backend follow-up: add a GET /insights endpoint that asks '
            'Groq to summarise this user\'s recent scan_results + '
            'feed_items, cache the result, and have this screen fetch it.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
