import 'package:flutter/material.dart';

import '../widgets/pressable.dart';

class NavDest {
  const NavDest(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// A Material 3 Expressive, Samsung One-UI-style floating navigation bar:
/// insets from the screen edges, fully rounded, sitting above a soft scrim that
/// fades the content behind it so the two never visually collide.
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
      height: 70 + 14 + bottomInset + 26,
      child: Stack(
        children: [
          // Fade scrim: transparent at the top, solid surface at the bottom,
          // so widgets scrolling under the floating bar don't peek through.
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
            left: 16,
            right: 16,
            bottom: 12 + bottomInset,
            child: _Pill(
              scheme: scheme,
              selectedIndex: selectedIndex,
              onSelect: onSelect,
              destinations: destinations,
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
      // Strong, clearly-visible shadow under the floating bar.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 30,
            spreadRadius: 1,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // A Material both clips the pill and provides the ink ancestor the
      // per-item InkResponse needs for its ripple.
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(35),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 70,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (var i = 0; i < destinations.length; i++)
                  Expanded(
                    child: _NavItem(
                      dest: destinations[i],
                      selected: i == selectedIndex,
                      scheme: scheme,
                      onTap: () => onSelect(i),
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

class _NavItem extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return Pressable(
      child: InkResponse(
        onTap: onTap,
        radius: 46,
        containedInkWell: false,
        highlightShape: BoxShape.circle,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // A perfect circle indicator around the icon (equal W/H).
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color:
                    selected ? scheme.secondaryContainer : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                selected ? dest.selectedIcon : dest.icon,
                size: 24,
                color: selected
                    ? scheme.onSecondaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              dest.label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
