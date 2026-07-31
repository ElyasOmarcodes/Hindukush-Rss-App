import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

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

  /// A lot of very small grains — the point is fine photographic noise, not a
  /// handful of visible dots. They're drawn with [Canvas.drawRawPoints] in a
  /// few alpha buckets, so this is still only a handful of draw calls.
  static const int _grainCount = 1400;

  /// How many opacity tiers the grain is bucketed into.
  static const int _buckets = 4;

  /// Grain diameter in logical pixels. Deliberately sub-pixel-ish so the burst
  /// reads as texture rather than as dots.
  static const double _grainSize = 1.15;

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
      Paint()..color = color.withValues(alpha: peak * envelope * 0.34),
    );

    // 2. The grain itself. Each speck twinkles on its own schedule — that
    //    staggering is what makes it read as noise instead of a ring. Specks
    //    are bucketed by brightness so the whole field costs only [_buckets]
    //    draw calls instead of one per speck.
    final geometry = _grainGeometry;
    final buckets = List<Float32List>.generate(
      _buckets,
      (_) => Float32List(_grainCount * 2),
    );
    final counts = List<int>.filled(_buckets, 0);

    for (var i = 0; i < _grainCount; i++) {
      final phase = geometry[i * 3 + 2];
      final local = _clamp01((t - phase) / (1.0 - phase));
      if (local <= 0) continue;
      final twinkle = math.sin(local * math.pi);
      if (twinkle <= 0.02) continue;

      var bucket = (twinkle * _buckets).floor();
      if (bucket >= _buckets) bucket = _buckets - 1;
      final n = counts[bucket];
      buckets[bucket][n * 2] = _position.dx + geometry[i * 3] * radius;
      buckets[bucket][n * 2 + 1] = _position.dy + geometry[i * 3 + 1] * radius;
      counts[bucket] = n + 1;
    }

    final grain = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _grainSize;
    for (var b = 0; b < _buckets; b++) {
      if (counts[b] == 0) continue;
      // Mid-point brightness of this bucket.
      final level = (b + 0.5) / _buckets;
      grain.color = color.withValues(alpha: _clamp01(peak * envelope * level));
      canvas.drawRawPoints(
        ui.PointMode.points,
        Float32List.sublistView(buckets[b], 0, counts[b] * 2),
        grain,
      );
    }

    canvas.restore();
  }

  /// Typed 0..1 clamp — `num.clamp` would widen the result back to `num`.
  static double _clamp01(double v) => v < 0.0 ? 0.0 : (v > 1.0 ? 1.0 : v);

  /// `[unitX, unitY, phase]` per speck, laid out flat. Built once per splash
  /// (so every tap gets a different grain pattern) and then only scaled by the
  /// current radius each frame.
  late final Float32List _grainGeometry = _buildGrains(_seed);

  static Float32List _buildGrains(int seed) {
    final rnd = math.Random(seed);
    final out = Float32List(_grainCount * 3);
    for (var i = 0; i < _grainCount; i++) {
      final angle = rnd.nextDouble() * math.pi * 2;
      // sqrt() spreads specks evenly over the disc instead of clumping them in
      // the middle.
      final distance = math.sqrt(rnd.nextDouble());
      out[i * 3] = math.cos(angle) * distance;
      out[i * 3 + 1] = math.sin(angle) * distance;
      out[i * 3 + 2] = rnd.nextDouble() * 0.5;
    }
    return out;
  }

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
