import 'package:flutter/material.dart';

/// A Material-style network image: rounded, tonal placeholder, graceful error
/// fallback and a smooth fade-in. Optionally tappable to open a full-screen,
/// zoomable viewer (used in the post view).
class MaterialImage extends StatelessWidget {
  const MaterialImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.heroTag,
    this.openFullScreen = false,
  });

  final String? url;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final Object? heroTag;
  final bool openFullScreen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(16);

    Widget image;
    if (url == null || url!.isEmpty) {
      image = _placeholder(scheme, icon: Icons.image_outlined);
    } else {
      image = Image.network(
        url!,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _placeholder(scheme);
        },
        errorBuilder: (context, error, stack) =>
            _placeholder(scheme, icon: Icons.broken_image_outlined),
        frameBuilder: (context, child, frame, wasSync) {
          if (wasSync) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            child: child,
          );
        },
      );
    }

    Widget result = ClipRRect(
      borderRadius: radius,
      child: SizedBox(width: width, height: height, child: image),
    );

    if (heroTag != null) {
      result = Hero(tag: heroTag!, child: result);
    }

    if (openFullScreen && url != null && url!.isNotEmpty) {
      result = GestureDetector(
        onTap: () => Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.black87,
            pageBuilder: (_, __, ___) =>
                _FullScreenImage(url: url!, heroTag: heroTag),
          ),
        ),
        child: result,
      );
    }
    return result;
  }

  Widget _placeholder(ColorScheme scheme, {IconData? icon}) => Container(
        width: width,
        height: height,
        color: scheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: icon == null
            ? null
            : Icon(icon, color: scheme.onSurfaceVariant, size: 32),
      );
}

class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.url, this.heroTag});
  final String url;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    Widget img = InteractiveViewer(
      minScale: 0.8,
      maxScale: 4,
      child: Center(child: Image.network(url, fit: BoxFit.contain)),
    );
    if (heroTag != null) img = Hero(tag: heroTag!, child: img);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: img),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
