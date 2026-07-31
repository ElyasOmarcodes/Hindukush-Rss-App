import 'package:flutter/material.dart';

import '../widgets/pressable.dart';

class NavDest {
  const NavDest(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// A Material 3 Expressive floating navigation bar in the Samsung One-UI /
/// Telegram style: a **wrap-content** rounded pill (only as wide as its items),
/// centred, floating above a soft fade scrim. The selected item sits in a
/// filled stadium indicator; every item shows its icon + label.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<NavDest> destinations;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return SizedBox(
      height: 66 + 12 + bottomInset + 24,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.surface.withValues(alpha: 0.0),
                      scheme.surface.withValues(alpha: 0.75),
                      scheme.surface,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 10 + bottomInset,
            child: Center(
              child: _Pill(
                scheme: scheme,
                selectedIndex: selectedIndex,
                onSelect: onSelect,
                destinations: destinations,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.scheme,
    required this.selectedIndex,
    required this.onSelect,
    required this.destinations,
  });

  final ColorScheme scheme;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<NavDest> destinations;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 28,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(34),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          // Wrap content: the pill is only as wide as its items.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < destinations.length; i++)
                _NavItem(
                  dest: destinations[i],
                  selected: i == selectedIndex,
                  scheme: scheme,
                  onTap: () => onSelect(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.dest,
    required this.selected,
    required this.scheme,
    required this.onTap,
  });

  final NavDest dest;
  final bool selected;
  final ColorScheme scheme;
  final VoidCallback onTap;

  /// Every item is exactly this wide, with no margin between them, so the pill
  /// stays as narrow as possible while the items keep an equal footprint.
  static const double width = 72;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final selected = widget.selected;
    final fg = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;

    // The "glassify" stroke: while the item is held down it gets a translucent
    // frosted fill and a bright hairline outline that fades away on release.
    final Color fill = selected
        ? scheme.secondaryContainer
        : _pressed
            ? scheme.onSurface.withValues(alpha: 0.10)
            : Colors.transparent;
    final Color stroke = _pressed
        ? scheme.primary.withValues(alpha: 0.70)
        : Colors.transparent;

    return SizedBox(
      width: _NavItem.width,
      child: Pressable(
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          customBorder: const StadiumBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: ShapeDecoration(
              color: fill,
              shape: StadiumBorder(
                side: BorderSide(color: stroke, width: 1.6),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(selected ? widget.dest.selectedIcon : widget.dest.icon,
                    size: 24, color: fg),
                const SizedBox(height: 3),
                Text(
                  widget.dest.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
