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
          SwitchListTile(
            title: const Text('Notify on new issue'),
            value: settings.notifyOnNewIssue,
            onChanged: notifier.setNotifyOnNewIssue,
          ),
          SwitchListTile(
            title: const Text('Notify on score drop'),
            value: settings.notifyOnScoreDrop,
            onChanged: notifier.setNotifyOnScoreDrop,
          ),
          ListTile(
            title: const Text('Minimum score drop to notify'),
            trailing: Text('${settings.scoreDropThreshold} pts'),
          ),
        ],
      ),
    );
  }
}
