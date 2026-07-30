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
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? scheme.secondaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? dest.selectedIcon : dest.icon,
                  size: 24,
                  color: selected
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            dest.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSecondaryContainer,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
