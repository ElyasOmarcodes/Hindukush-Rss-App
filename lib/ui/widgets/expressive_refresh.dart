import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';

import 'contained_loading_indicator.dart';

/// A Material 3 Expressive pull-to-refresh: dragging down gently pushes the
/// whole page down and reveals a *contained loading indicator* at the top
/// (instead of the stock circular arrow). Matches the reference video/image1.
class ExpressiveRefresh extends StatelessWidget {
  const ExpressiveRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.topInset = 0,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  /// Extra top offset so the indicator clears an app bar, if any.
  final double topInset;

  static const _revealHeight = 92.0;

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: onRefresh,
      offsetToArmed: _revealHeight,
      builder: (context, child, controller) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final raw = controller.value;
            final drag = raw.clamp(0.0, 1.4);
            final dy = drag * _revealHeight * 0.9;
            final v = raw.clamp(0.0, 1.0);
            return Stack(
              children: [
                Transform.translate(
                  offset: Offset(0, dy),
                  child: child,
                ),
                Positioned(
                  top: topInset + 6 + v * 14,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: controller.isLoading ? 1.0 : v,
                      child: Transform.scale(
                        scale: 0.5 + 0.5 * (controller.isLoading ? 1.0 : v),
                        child: const Center(
                          child: ContainedLoadingIndicator(size: 46),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      child: child,
    );
  }
}
