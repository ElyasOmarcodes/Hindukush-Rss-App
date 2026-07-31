import 'package:flutter/material.dart';

/// Overlays soft gradients at the top and/or bottom edges so scrolling content
/// dissolves gently into the surface instead of ending with a hard line.
///
/// Used at the root so every tab shares the same fade behind the floating
/// navigation bar, and (top-only) on the Home tab which has no app bar.
class EdgeFade extends StatelessWidget {
  const EdgeFade({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.topHeight = 22,
    this.bottomHeight = 120,
    this.topOffset = 0,
  });

  final Widget child;
  final bool top;
  final bool bottom;
  final double topHeight;
  final double bottomHeight;

  /// Where the top fade begins (e.g. just below an app bar).
  final double topOffset;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Stack(
      children: [
        child,
        if (top)
          Positioned(
            top: topOffset,
            left: 0,
            right: 0,
            height: topHeight,
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
        if (bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: bottomHeight,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      surface,
                      surface.withValues(alpha: 0.0),
                    ],
                    stops: const [0.35, 1],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A thin pinned sliver placed directly after a pinned app bar. It always keeps
/// a short strip of surface→transparent gradient below the bar, so list content
/// scrolls *under* it and fades smoothly into the app bar instead of cutting at
/// a hard edge (the iOS/Telegram "large title" feel).
class SliverFadeUnderAppBar extends StatelessWidget {
  const SliverFadeUnderAppBar({super.key, this.height = 20});

  final double height;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _FadeDelegate(height: height, surface: surface),
    );
  }
}

class _FadeDelegate extends SliverPersistentHeaderDelegate {
  _FadeDelegate({required this.height, required this.surface});

  final double height;
  final Color surface;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [surface, surface.withValues(alpha: 0.0)],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_FadeDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.surface != surface;
}

/// Backwards-compatible top-only fade (kept for any remaining call sites).
class TopEdgeFade extends StatelessWidget {
  const TopEdgeFade({super.key, required this.child, this.height = 20});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) =>
      EdgeFade(top: true, bottom: false, topHeight: height, child: child);
}
