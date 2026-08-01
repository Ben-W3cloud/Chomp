/// Reveal — one entrance choreography for all staggered content.
///
/// Wraps any widget and eases it in: fade + rise on the spring curve,
/// delayed by [delayMs] so lists cascade instead of slamming in.
/// Uses only transform/opacity — no layout animation.

library;

import 'package:flutter/material.dart';
import '../core/theme.dart';

class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.offset = const Offset(0, 0.1),
  });

  final Widget child;
  final double delayMs;
  final Offset offset;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.standard,
  );

  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: AppMotion.curve);
  late final Animation<Offset> _slide = Tween<Offset>(
          begin: widget.offset, end: Offset.zero)
      .animate(CurvedAnimation(parent: _controller, curve: AppMotion.curve));

  @override
  void initState() {
    super.initState();
    if (widget.delayMs == 0) {
      _controller.forward();
    } else {
      Future.delayed(Duration(milliseconds: widget.delayMs.round()), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
