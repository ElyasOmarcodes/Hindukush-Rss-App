import 'package:flutter/material.dart';

/// A filled Material 3 Expressive button whose corner radius morphs on press
/// (fully-rounded → tighter), the signature expressive touch feedback.
class ExpressiveButton extends StatefulWidget {
  const ExpressiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.foreground,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final Color? foreground;

  @override
  State<ExpressiveButton> createState() => _ExpressiveButtonState();
}

class _ExpressiveButtonState extends State<ExpressiveButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = widget.color ?? scheme.primary;
    final fg = widget.foreground ?? scheme.onPrimary;
    final radius = _down ? 14.0 : 26.0;

    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: fg, fontWeight: FontWeight.w700),
          child: IconTheme.merge(
            data: IconThemeData(color: fg),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
