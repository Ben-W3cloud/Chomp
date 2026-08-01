/// Splash — branded cold-start moment.
///
/// Native splash paints `#0E0B12` instantly (no white flash), then this
/// route eases the lockup in on the spring curve, checks for a stored
/// session token, and routes to Home (returning user) or Welcome (new).

library;

import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/api_client.dart';
import '../../widgets/brand_mark.dart';
import '../home/home_screen.dart';
import '../onboarding/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.expressive,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.6, curve: AppMotion.curve),
  );
  late final Animation<double> _rise = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.15, 1, curve: AppMotion.curve),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _route();
  }

  Future<void> _route() async {
    // Give the mark a beat to breathe before moving on.
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final signedIn = await ApiClient.instance.sessionToken != null;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: AppMotion.standard,
        pageBuilder: (_, __, ___) =>
            signedIn ? const HomeScreen() : const WelcomeScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: AppMotion.curve),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          // Ambient magenta glow, upper-left.
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.brand.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0, 0.12), end: Offset.zero)
                    .animate(_rise),
                child: const BrandLockup(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
