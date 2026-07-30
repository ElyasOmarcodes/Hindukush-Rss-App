import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../data/cache/image_cache.dart';

/// A Material-style network image backed by [DiskImageCache]: rounded, tonal
/// placeholder, graceful error fallback, smooth fade-in, cached to disk so it
/// loads once and works offline. Optionally opens a full-screen zoomable viewer.
class MaterialImage extends StatefulWidget {
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
  State<MaterialImage> createState() => _MaterialImageState();
}

class _MaterialImageState extends State<MaterialImage> {
  Uint8List? _bytes;
  bool _loading = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _bytes = DiskImageCache.instance.peek(widget.url);
    if (_bytes == null) _load();
  }

  @override
  void didUpdateWidget(MaterialImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _bytes = DiskImageCache.instance.peek(widget.url);
      _error = false;
      if (_bytes == null) _load();
    }
  }

  Future<void> _load() async {
    final url = widget.url;
    if (url == null || url.isEmpty) return;
    setState(() => _loading = true);
    final bytes = await DiskImageCache.instance.load(url);
    if (!mounted || url != widget.url) return;
    setState(() {
      _bytes = bytes;
      _error = bytes == null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = widget.borderRadius ?? BorderRadius.circular(16);

    Widget content;
    if (widget.url == null || widget.url!.isEmpty) {
      content = _placeholder(scheme, icon: Icons.image_outlined);
    } else if (_bytes != null) {
      content = Image.memory(
        _bytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) =>
            _placeholder(scheme, icon: Icons.broken_image_outlined),
      );
    } else if (_error) {
      content = _placeholder(scheme, icon: Icons.broken_image_outlined);
    } else {
      content = _placeholder(scheme);
    }

    Widget result = ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          child: KeyedSubtree(
            key: ValueKey(_bytes != null),
            child: content,
          ),
        ),
      ),
    );

    if (widget.heroTag != null) {
      result = Hero(tag: widget.heroTag!, child: result);
    }

    if (widget.openFullScreen && _bytes != null) {
      result = GestureDetector(
        onTap: () => Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.black87,
            pageBuilder: (_, __, ___) =>
                _FullScreenImage(bytes: _bytes!, heroTag: widget.heroTag),
          ),
        ),
        child: result,
      );
    }
    return result;
  }

  Widget _placeholder(ColorScheme scheme, {IconData? icon}) => Container(
        width: widget.width,
        height: widget.height,
        color: scheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: icon == null
            ? null
            : Icon(icon, color: scheme.onSurfaceVariant, size: 32),
      );
}

class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.bytes, this.heroTag});
  final Uint8List bytes;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    Widget img = InteractiveViewer(
      minScale: 0.8,
      maxScale: 4,
      child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
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
