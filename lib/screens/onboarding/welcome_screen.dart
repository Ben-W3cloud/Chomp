/// Welcome/onboarding screen.
///
/// The first screen users see when they open the app without being
/// signed in. Displays the app name, tagline, and a "Connect GitHub"
/// button that initiates the OAuth flow.
///
/// Listens to auth state changes and automatically navigates to
/// [HomeScreen] when the user signs in successfully.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // Listen for auth state changes to navigate on sign in
    ref.listen(authProvider, (previous, next) {
      if (next.isSignedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chomp',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('GitHub analytics, watched by AI, on your phone.'),
              const SizedBox(height: 32),
              if (auth.error != null) ...[
                Text(auth.error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
              ],
              FilledButton(
                onPressed: auth.isLoading
                    ? null
                    : () => ref.read(authProvider.notifier).signInWithGitHub(),
                child: auth.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Connect GitHub'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
