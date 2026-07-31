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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
    final fg = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    // Equal-width slot for every item; a small margin keeps the ripple/stroke
    // inside the pill and consistent across items.
    return SizedBox(
      width: 80,
      child: Center(
        child: Pressable(
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: ShapeDecoration(
                color:
                    selected ? scheme.secondaryContainer : Colors.transparent,
                shape: const StadiumBorder(),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(selected ? dest.selectedIcon : dest.icon,
                      size: 24, color: fg),
                  const SizedBox(height: 3),
                  Text(
                    dest.label,
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
      ),
    );
  }
}
