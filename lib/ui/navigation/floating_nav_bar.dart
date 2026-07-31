import 'package:flutter/material.dart';

import '../widgets/glass_highlight.dart';

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

/// The gap between the pill's edge and an item's indicator — identical on all
/// four sides because both shapes are stadiums (see [_Pill.build]).
const double _inset = 6;

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
        // A radius this large always resolves to a true stadium, whatever the
        // pill's measured height turns out to be.
        borderRadius: BorderRadius.circular(999),
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
        // A *stadium*, not a fixed 34px radius. The item indicator is a
        // stadium too, so the two outlines are now exact concentric offsets:
        // pill radius (height/2) − item radius (item height/2) equals the
        // padding, which makes the gap precisely [_inset] everywhere, on the
        // curved caps just as much as on the straight edges. With a fixed
        // corner radius they were not concentric, so no padding value could
        // ever make the gap uniform.
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(_inset),
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
    // The active destination is drawn in the primary colour.
    final fg = selected ? scheme.primary : scheme.onSurfaceVariant;

    // The indicator is the outermost box and the ink surface lives *inside* it:
    //
    //  * There is no press scale any more. The scale shrank the indicator to
    //    93% while the ink highlight kept the item's full size, so on press you
    //    saw the highlight peeking out around the smaller indicator — that was
    //    the "second container".
    //  * The InkWell has its own transparent [Material], so the splash is
    //    painted *above* the indicator's fill. Previously the ink belonged to
    //    the pill's Material underneath, so the opaque indicator of the active
    //    destination hid the sparkle completely.
    //  * The tap target is still the item's full size, so taps aren't dropped.
    return SizedBox(
      width: _NavItem.width,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: selected ? scheme.secondaryContainer : Colors.transparent,
          shape: const StadiumBorder(),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Stack(
              alignment: Alignment.center,
              children: [
                // The frosted-glass press state, faded in and out smoothly.
                // Only for inactive destinations — the active one already has
                // its filled indicator, and stacking the glass edge on top of
                // that read as two outlines around one container.
                if (!selected)
                  Positioned.fill(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _pressed ? 1 : 0),
                      duration: Duration(milliseconds: _pressed ? 180 : 320),
                      curve: Curves.easeOutCubic,
                      builder: (_, t, __) => GlassHighlight(progress: t),
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // A gentle lift when the destination becomes active.
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1, end: selected ? 1.12 : 1.0),
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutBack,
                      builder: (_, s, child) =>
                          Transform.scale(scale: s, child: child),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: ScaleTransition(scale: anim, child: child),
                        ),
                        child: Icon(
                          selected
                              ? widget.dest.selectedIcon
                              : widget.dest.icon,
                          key: ValueKey(selected),
                          size: 24,
                          color: fg,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: fg,
                      ),
                      child: Text(
                        widget.dest.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
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
