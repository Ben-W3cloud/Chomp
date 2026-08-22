/// Chomp app entry point.
///
/// Initializes env, Firebase, notifications, and settings (persisted
/// theme) before `runApp`. Routing starts at [SplashScreen], which
/// resolves to Home or Welcome based on the stored session token.

library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/env.dart';
import 'core/theme.dart';
import 'services/notification_service.dart';
import 'providers/settings_provider.dart';
import 'screens/splash/splash_screen.dart';

/// Background message handler for Firebase Cloud Messaging.
///
/// Runs in a separate isolate when a push arrives while the app is
/// backgrounded or terminated. The real work already happened
/// server-side; this just surfaces a local notification.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.instance.init();
  final title = message.notification?.title ?? 'Chomp';
  final body = message.notification?.body ?? 'A watched repo has an update.';
  await NotificationService.instance.showAlert(title: title, body: body);
}

/// App entry point.
Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Env.load();
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await NotificationService.instance.init();

    // Load persisted settings (theme, notification prefs) before the first
    // frame so the user's chosen theme is applied immediately — no flash
    // of the default.
    final container = ProviderContainer();
    await container.read(settingsProvider.notifier).load();

    runApp(
        UncontrolledProviderScope(container: container, child: const ChompApp()));
  }, (error, stack) {
    debugPrint('UNCAUGHT ERROR: $error');
    debugPrint('$stack');
  });
}

class ChompApp extends ConsumerWidget {
  const ChompApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp(
      title: 'Chomp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (settings.themeMode) {
        ThemeModePref.light => ThemeMode.light,
        ThemeModePref.dark => ThemeMode.dark,
        ThemeModePref.system => ThemeMode.system,
      },
      home: const SplashScreen(),
    );
  }
}
