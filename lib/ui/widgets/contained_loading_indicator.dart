import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A Material 3 Expressive "contained loading indicator": a soft filled
/// container holding an animated, morphing progress mark. Appears with a gentle
/// scale + fade so it can be dropped in above content during a refresh.
class ContainedLoadingIndicator extends StatefulWidget {
  const ContainedLoadingIndicator({super.key, this.size = 48});

  final double size;

  @override
  State<ContainedLoadingIndicator> createState() =>
      _ContainedLoadingIndicatorState();
}

class _ContainedLoadingIndicatorState extends State<ContainedLoadingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat();
  late final AnimationController _in =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 380))
        ..forward();

  @override
  void dispose() {
    _spin.dispose();
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appear = CurvedAnimation(parent: _in, curve: Curves.elasticOut);
    return ScaleTransition(
      scale: appear,
      child: FadeTransition(
        opacity: _in,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(AppTheme.rMedium),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _spin,
              builder: (context, _) => CustomPaint(
                size: Size.square(widget.size * 0.5),
                painter: _MorphPainter(
                  progress: _spin.value,
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws a rounded, rotating "cog/flower" mark that morphs between shapes —
/// evoking the expressive loading indicator's shape-shifting motion.
class _MorphPainter extends CustomPainter {
  _MorphPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final t = progress * 2 * math.pi;
    final lobes = 6;
    final morph = (math.sin(progress * 2 * math.pi) + 1) / 2; // 0..1
    final path = Path();
    const steps = 120;
    for (var i = 0; i <= steps; i++) {
      final a = (i / steps) * 2 * math.pi;
      final wobble = 1 + 0.28 * morph * math.cos(lobes * a);
      final r = radius * wobble;
      final p = Offset(
        center.dx + r * math.cos(a + t),
        center.dy + r * math.sin(a + t),
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MorphPainter old) => old.progress != progress;
}

/// A full-height centered loading state.
class CenteredLoading extends StatelessWidget {
  const CenteredLoading({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: ContainedLoadingIndicator(size: 56));
}
