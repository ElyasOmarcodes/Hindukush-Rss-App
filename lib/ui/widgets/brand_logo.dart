import 'package:flutter/material.dart';

/// The Hindukush brand mark (a single-colour silhouette PNG with a transparent
/// background). [color] recolours it via srcIn so it always contrasts with the
/// current theme; pass null to keep the original brand purple.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 64, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand_icon.png',
      width: size,
      height: size,
      color: color,
      colorBlendMode: color != null ? BlendMode.srcIn : null,
      filterQuality: FilterQuality.medium,
    );
  }
}
