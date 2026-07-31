/// Notification settings screen.
///
/// Allows users to configure their notification preferences:
/// - Whether to notify on new issues found during scans
/// - Whether to notify when security scores drop
/// - Minimum score drop threshold for notifications
///
/// Settings are currently stored in-memory only and will reset
/// when the app restarts. During the UI polish pass, persist these
/// to local storage or a backend endpoint.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          // Toggle for new issue notifications
          SwitchListTile(
            title: const Text('Notify on new issue'),
            value: settings.notifyOnNewIssue,
            onChanged: notifier.setNotifyOnNewIssue,
          ),
          // Toggle for score drop notifications
          SwitchListTile(
            title: const Text('Notify on score drop'),
            value: settings.notifyOnScoreDrop,
            onChanged: notifier.setNotifyOnScoreDrop,
          ),
          // Score drop threshold setting
          ListTile(
            title: const Text('Minimum score drop to notify'),
            trailing: Text('${settings.scoreDropThreshold} pts'),
          ),
        ],
      ),
    );
  }
}
