import 'package:flutter/material.dart';

/// A centered "play" overlay marking a thumbnail as a video.
class VideoBadge extends StatelessWidget {
  const VideoBadge({super.key, this.size = 34});
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white70, width: 1.5),
          ),
          child: Icon(Icons.play_arrow_rounded,
              color: Colors.white, size: size * 0.66),
        ),
      ),
    );
  }
}
