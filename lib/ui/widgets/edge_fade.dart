import 'package:flutter/material.dart';

/// Overlays a soft gradient at the top edge so content fades gently under the
/// status bar / app bar instead of ending with a hard line. Kept subtle.
class TopEdgeFade extends StatelessWidget {
  const TopEdgeFade({super.key, required this.child, this.height = 20});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: height,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [surface, surface.withValues(alpha: 0.0)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
