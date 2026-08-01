/// Brand mark — a machined double-bezel tile with an animated radar
/// sweep. The Chomp identity: a scan orbiting a repo.
///
/// Motion is transform/opacity only; the sweep is a `CustomPainter`
/// re-painted each tick on the animation controller (no layout cost).

library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

/// Full lockup: mark + wordmark. Use on splash and welcome.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.size = 96, this.showWordmark = true});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: size),
        if (showWordmark) ...[
          const SizedBox(height: 28),
          Text(
            'Chomp',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ],
    );
  }
}

/// The radar tile alone.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(size * 0.055),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceHigh.withValues(alpha: 0.5)
            : AppColors.lightHairline,
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(
          color: isDark ? AppColors.darkHairline : AppColors.lightHairline,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: isDark ? 0.18 : 0.12),
            blurRadius: size * 0.45,
            spreadRadius: -size * 0.05,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.185),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.darkSurfaceHigh, AppColors.darkSurface]
                : [Colors.white, AppColors.lightSurface],
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : AppColors.lightHairline,
              blurRadius: size * 0.12,
              offset: Offset(0, size * 0.03),
            ),
            BoxShadow(
              color: const Color(0x33FFFFFF),
              blurRadius: size * 0.1,
              offset: Offset(0, -size * 0.015),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.185),
          child: SizedBox(
            width: size * 0.89,
            height: size * 0.89,
            child:
                _RadarMark(brand: AppColors.brand, color: tokens.surfaceHigh),
          ),
        ),
      ),
    );
  }
}

class _RadarMark extends StatefulWidget {
  const _RadarMark({required this.brand, required this.color});

  final Color brand;
  final Color color;

  @override
  State<_RadarMark> createState() => _RadarMarkState();
}

class _RadarMarkState extends State<_RadarMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _RadarSweepPainter(
          brand: widget.brand,
          base: widget.color,
          sweep: _controller.value,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _RadarSweepPainter extends CustomPainter {
  _RadarSweepPainter(
      {required this.brand, required this.base, required this.sweep});

  final Color brand;
  final Color base;
  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    // Stationary rings.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = base.withValues(alpha: 0.45);
    for (final r in [0.32, 0.55, 0.78]) {
      canvas.drawCircle(center, radius * r, ring);
    }

    // Sweep wedge — magenta, fading along the arc.
    final sweepRect = Rect.fromCircle(center: center, radius: radius);
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [
          Colors.transparent,
          Colors.transparent,
          brand.withValues(alpha: 0.28),
          brand.withValues(alpha: 0.55),
        ],
        stops: const [0.0, 0.82, 0.95, 1.0],
        transform: GradientRotation(sweep * math.pi * 2),
      ).createShader(sweepRect);
    canvas.drawCircle(center, radius, sweepPaint);

    // Sweep head.
    final headAngle = sweep * math.pi * 2;
    final head = Offset(
      center.dx + math.cos(headAngle) * radius,
      center.dy + math.sin(headAngle) * radius,
    );
    canvas.drawCircle(head, radius * 0.055, Paint()..color = brand);
  }

  @override
  bool shouldRepaint(_RadarSweepPainter old) =>
      old.sweep != sweep || old.brand != brand || old.base != base;
}
