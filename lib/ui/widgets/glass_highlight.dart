import 'package:flutter/material.dart';

/// A frosted-glass press highlight in the Telegram style: a translucent
/// gradient pane with a bright, *gradient* hairline edge that catches the light
/// on one side and fades out on the other.
///
/// A plain [BorderSide] can only be one flat colour, which reads as an ordinary
/// outline; the gradient edge is what makes it look like glass, so the outline
/// is stroked with a shader here instead.
class GlassHighlight extends StatelessWidget {
  const GlassHighlight({
    super.key,
    required this.progress,
    this.borderRadius,
  });

  /// 0 = invisible, 1 = fully lit.
  final double progress;

  /// Defaults to a stadium (fully rounded) shape.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: CustomPaint(
        painter: _GlassPainter(
          progress: progress,
          radius: borderRadius,
          // The pane picks up the surface's own light, the edge picks up the
          // accent — that combination is what sells the glass.
          paneColor: dark ? Colors.white : scheme.onSurface,
          edgeColor: scheme.primary,
          glowColor: dark ? Colors.white : scheme.primary,
        ),
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  _GlassPainter({
    required this.progress,
    required this.radius,
    required this.paneColor,
    required this.edgeColor,
    required this.glowColor,
  });

  final double progress;
  final BorderRadius? radius;
  final Color paneColor;
  final Color edgeColor;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = radius == null
        ? RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2))
        : radius!.toRRect(rect);
    final p = progress.clamp(0.0, 1.0);

    // 1. The pane: brighter at the top-left, almost clear at the bottom-right.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            paneColor.withValues(alpha: 0.20 * p),
            paneColor.withValues(alpha: 0.05 * p),
          ],
        ).createShader(rect),
    );

    // 2. A soft inner glow just under the top edge.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [
            glowColor.withValues(alpha: 0.22 * p),
            glowColor.withValues(alpha: 0.0),
          ],
        ).createShader(rect),
    );

    // 3. The lit edge — a gradient stroke, bright where the "light" hits.
    canvas.drawRRect(
      rrect.deflate(0.7),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            edgeColor.withValues(alpha: 0.85 * p),
            edgeColor.withValues(alpha: 0.30 * p),
            edgeColor.withValues(alpha: 0.08 * p),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlassPainter old) =>
      old.progress != progress ||
      old.paneColor != paneColor ||
      old.edgeColor != edgeColor ||
      old.glowColor != glowColor ||
      old.radius != radius;
}
