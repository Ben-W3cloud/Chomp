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

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Runs in a separate isolate when a push arrives while the app is
  // backgrounded or terminated. Keep this minimal — the real work
  // already happened server-side; this just surfaces a local notification.
  await Firebase.initializeApp();
  await NotificationService.instance.init();
  final title = message.notification?.title ?? 'Chomp';
  final body = message.notification?.body ?? 'A watched repo has an update.';
  await NotificationService.instance.showAlert(title: title, body: body);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: ChompApp()));
}

class ChompApp extends ConsumerStatefulWidget {
  const ChompApp({super.key});

  @override
  ConsumerState<ChompApp> createState() => _ChompAppState();
}

class _ChompAppState extends ConsumerState<ChompApp> {
  @override
  void initState() {
    super.initState();
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
