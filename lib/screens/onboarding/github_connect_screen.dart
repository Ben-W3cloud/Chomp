/// GitHub connection screen.
///
/// Currently folded into [WelcomeScreen]'s single "Connect GitHub"
/// button. Kept as its own route stub in case you want a distinct
/// step later (e.g. explaining scopes before the OAuth prompt).

import 'package:flutter/material.dart';
import 'welcome_screen.dart';

class GitHubConnectScreen extends StatelessWidget {
  const GitHubConnectScreen({super.key});

  @override
  Widget build(BuildContext context) => const WelcomeScreen();
}
