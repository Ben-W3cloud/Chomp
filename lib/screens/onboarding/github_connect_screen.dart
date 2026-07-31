import 'package:flutter/material.dart';
import 'welcome_screen.dart';

/// Currently folded into WelcomeScreen's single "Connect GitHub"
/// button. Kept as its own route stub in case you want a distinct
/// step later (e.g. explaining scopes before the OAuth prompt).
class GitHubConnectScreen extends StatelessWidget {
  const GitHubConnectScreen({super.key});

  @override
  Widget build(BuildContext context) => const WelcomeScreen();
}
