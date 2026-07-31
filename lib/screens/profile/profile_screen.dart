/// User profile screen.
///
/// Displays user information and provides access to:
/// - Watchlist management
/// - Notification settings
/// - GitHub account disconnection
///
/// Shows the user's GitHub username and provides navigation to
/// other profile-related screens.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'watchlist_manager_screen.dart';
import 'notification_settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          // User info section
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(auth.user?.githubUsername ?? 'Not signed in'),
          ),
          // Watchlist management
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Manage Watchlist'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WatchlistManagerScreen()),
            ),
          ),
          // Notification settings
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notification Settings'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const NotificationSettingsScreen()),
            ),
          ),
          // Sign out
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Disconnect GitHub'),
            onTap: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}
