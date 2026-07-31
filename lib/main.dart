/// Chomp app entry point.
/// Initializes Firebase, notifications, and Riverpod state management.
/// Routes to either the home screen (if signed in) or welcome screen
/// (if not signed in).
///
/// Also registers a background message handler for Firebase Cloud
/// Messaging to display notifications when the app is backgrounded.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/env.dart';
import 'core/theme.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/home/home_screen.dart';

/// Background message handler for Firebase Cloud Messaging.
///
/// Runs in a separate isolate when a push arrives while the app is
/// backgrounded or terminated. Keep this minimal — the real work
/// already happened server-side; this just surfaces a local notification.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.instance.init();
  final title = message.notification?.title ?? 'Chomp';
  final body = message.notification?.body ?? 'A watched repo has an update.';
  await NotificationService.instance.showAlert(title: title, body: body);
}

/// App entry point.
///
/// Initializes all required services before running the app:
/// 1. Flutter bindings
/// 2. Environment variables from .env
/// 3. Firebase Core
/// 4. Firebase Messaging background handler
/// 5. Local notifications
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: ChompApp()));
}

/// Root app widget.
///
/// Wraps the app in Riverpod's ProviderScope for state management.
/// Handles auth-based routing: shows HomeScreen if signed in,
/// otherwise shows WelcomeScreen.
class ChompApp extends ConsumerStatefulWidget {
  const ChompApp({super.key});

  @override
  ConsumerState<ChompApp> createState() => _ChompAppState();
}

class _ChompAppState extends ConsumerState<ChompApp> {
  @override
  void initState() {
    super.initState();
    // Try to restore the user's session on app startup
    Future.microtask(() => ref.read(authProvider.notifier).restoreSession());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    return MaterialApp(
      title: 'Chomp',
      debugShowCheckedModeBanner: false,
      theme: ChompTheme.light(),
      darkTheme: ChompTheme.dark(),
      home: authState.isSignedIn ? const HomeScreen() : const WelcomeScreen(),
    );
  }
}
