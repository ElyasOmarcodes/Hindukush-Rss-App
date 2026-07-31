import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A deliberately bold "noise / sparkle" tap splash.
///
/// Flutter's stock [InkSparkle] runs for a fixed ~0.6s and is very faint on
/// light surfaces. This splash keeps the same idea — a burst of grain that
/// expands out of the touch point — but runs much longer and much stronger so
/// it reads clearly in both the light and the dark theme.
class NoiseSplash extends InteractiveInkFeature {
  NoiseSplash({
    required MaterialInkController controller,
    required super.referenceBox,
    required super.color,
    required Offset position,
    required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    super.customBorder,
    double? radius,
    super.onRemoved,
  })  : _position = position,
        _textDirection = textDirection,
        _borderRadius = borderRadius ?? BorderRadius.zero,
        _clipCallback =
            _computeClipCallback(referenceBox, containedInkWell, rectCallback),
        _targetRadius =
            radius ?? _computeTargetRadius(referenceBox, rectCallback),
        _seed = _entropy.nextInt(1 << 30),
        super(controller: controller) {
    _anim = AnimationController(duration: duration, vsync: controller.vsync)
      ..addListener(controller.markNeedsPaint)
      ..addStatusListener(_onStatus)
      ..forward();
    controller.addInkFeature(this);
  }

  /// Well over twice the length of the stock sparkle, so the grain is easy to
  /// actually see rather than being a subliminal flicker.
  static const Duration duration = Duration(milliseconds: 1150);

  /// How many grains make up the burst.
  static const int _grainCount = 130;

  static final math.Random _entropy = math.Random();

  final Offset _position;
  final TextDirection _textDirection;
  final BorderRadius _borderRadius;
  final RectCallback? _clipCallback;
  final double _targetRadius;
  final int _seed;

  late final AnimationController _anim;

  /// Use this as [ThemeData.splashFactory].
  static const InteractiveInkFeatureFactory splashFactory =
      _NoiseSplashFactory();

  bool _disposed = false;

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) dispose();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _anim.dispose();
    super.dispose();
  }

  @override
  void paintFeature(Canvas canvas, Matrix4 transform) {
    final t = _clamp01(_anim.value);
    if (t <= 0) return;

    // The burst grows out of the touch point and slightly overshoots the box.
    final eased = Curves.easeOutCubic.transform(t);
    final radius = _targetRadius * (0.22 + 0.98 * eased);

    // Envelope: snap in, hold bright for most of the run, then ease away.
    final double envelope;
    if (t < 0.10) {
      envelope = t / 0.10;
    } else {
      envelope =
          Curves.easeOutCubic.transform(_clamp01(1.0 - (t - 0.10) / 0.90));
    }
    if (envelope <= 0.01) return;

    final peak = color.a;

    canvas.save();
    final origin = MatrixUtils.getAsTranslation(transform);
    if (origin == null) {
      canvas.transform(transform.storage);
    } else {
      canvas.translate(origin.dx, origin.dy);
    }

    // Clip to the ink well exactly like the stock splashes do, so the grain
    // never spills outside a card / stadium / rounded button.
    final rect = _clipCallback?.call() ?? (Offset.zero & referenceBox.size);
    final border = customBorder;
    if (border != null) {
      canvas.clipPath(border.getOuterPath(rect, textDirection: _textDirection));
    } else if (_borderRadius != BorderRadius.zero) {
      canvas.clipRRect(RRect.fromRectAndCorners(
        rect,
        topLeft: _borderRadius.topLeft,
        topRight: _borderRadius.topRight,
        bottomLeft: _borderRadius.bottomLeft,
        bottomRight: _borderRadius.bottomRight,
      ));
    } else {
      canvas.clipRect(rect);
    }

    // 1. A soft wash so the burst has some body behind the grain.
    canvas.drawCircle(
      _position,
      radius,
      Paint()..color = color.withValues(alpha: peak * envelope * 0.42),
    );

    // 2. The grain itself — every dot twinkles on its own schedule, which is
    //    what gives the effect its "noise" character.
    final rnd = math.Random(_seed);
    final grain = Paint();
    for (var i = 0; i < _grainCount; i++) {
      final angle = rnd.nextDouble() * math.pi * 2;
      // sqrt() spreads the dots evenly over the disc instead of clumping them
      // in the middle.
      final distance = math.sqrt(rnd.nextDouble());
      final phase = rnd.nextDouble() * 0.45;
      final size = 1.8 + rnd.nextDouble() * 3.8;

      final local = _clamp01((t - phase) / (1.0 - phase));
      if (local <= 0) continue;
      final twinkle = math.sin(local * math.pi);
      if (twinkle <= 0.01) continue;

      grain.color =
          color.withValues(alpha: _clamp01(peak * envelope * twinkle));
      canvas.drawCircle(
        _position +
            Offset(math.cos(angle), math.sin(angle)) * (distance * radius),
        size * (0.55 + 0.45 * twinkle),
        grain,
      );
    }

    canvas.restore();
  }

  /// Typed 0..1 clamp — `num.clamp` would widen the result back to `num`.
  static double _clamp01(double v) => v < 0.0 ? 0.0 : (v > 1.0 ? 1.0 : v);

  static RectCallback? _computeClipCallback(
    RenderBox referenceBox,
    bool containedInkWell,
    RectCallback? rectCallback,
  ) {
    if (rectCallback != null) return rectCallback;
    if (containedInkWell) return () => Offset.zero & referenceBox.size;
    return null;
  }

  static double _computeTargetRadius(
    RenderBox referenceBox,
    RectCallback? rectCallback,
  ) {
    final size = rectCallback != null ? rectCallback().size : referenceBox.size;
    // Half of the longest diagonal — always reaches every corner.
    return math.max(
          size.bottomRight(Offset.zero).distance,
          (size.topRight(Offset.zero) - size.bottomLeft(Offset.zero)).distance,
        ) /
        2.0;
  }
}

class _NoiseSplashFactory extends InteractiveInkFeatureFactory {
  const _NoiseSplashFactory();

  @override
  InteractiveInkFeature create({
    required MaterialInkController controller,
    required RenderBox referenceBox,
    required Offset position,
    required Color color,
    required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    VoidCallback? onRemoved,
  }) {
    return NoiseSplash(
      controller: controller,
      referenceBox: referenceBox,
      color: color,
      position: position,
      textDirection: textDirection,
      containedInkWell: containedInkWell,
      rectCallback: rectCallback,
      borderRadius: borderRadius,
      customBorder: customBorder,
      radius: radius,
      onRemoved: onRemoved,
    );
  }
}
