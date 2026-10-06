import 'package:flutter/material.dart';

import '../../../core/config/feeds.dart';
import '../../../core/localization/strings.dart';
import '../../navigation/routes.dart';
import '../../widgets/pressable.dart';
import 'category_card.dart';

/// The Home sections as a two-column grid (three on wide screens).
///
/// Sub-sections: a grid tile has no room for an inline expander, so a section
/// that has children shows a small "layers" count, and tapping it opens a
/// bottom sheet listing "All <section>" followed by each sub-section — the
/// standard Material pattern for drilling into a group from a grid.
class SectionGrid extends StatelessWidget {
  const SectionGrid({super.key, required this.lang});

  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final entries = <(FeedCategory, int)>[
      for (var i = 0; i < kSections.length; i++)
        if (kSections[i].availableFor(lang)) (kSections[i], i),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final columns = constraints.maxWidth >= 600 ? 3 : 2;
        final tileWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var n = 0; n < entries.length; n++)
              SizedBox(
                width: tileWidth,
                child: _Stagger(
                  index: n,
                  child: _GridTile(
                    section: entries[n].$1,
                    colorIndex: entries[n].$2,
                    lang: lang,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.section,
    required this.colorIndex,
    required this.lang,
  });

  final FeedCategory section;
  final int colorIndex;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = S.of(lang);
    final children =
        section.children.where((c) => c.availableFor(lang)).toList();
    final hasChildren = children.isNotEmpty;

    return Pressable(
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => hasChildren
              ? showSubSections(context, section, children, colorIndex, lang)
              : openCategory(context, section),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              height: 112,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Badge(
                        icon: iconForCategory(section.id),
                        color: badgeColorFor(colorIndex),
                        size: 46,
                      ),
                      const Spacer(),
                      if (hasChildren)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.layers_rounded,
                                  size: 13, color: scheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                '${children.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    section.label(lang),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  if (hasChildren) ...[
                    const SizedBox(height: 2),
                    Text(
                      s.subSectionsN(children.length),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The bottom sheet for a section with sub-sections: "All <section>" first,
/// then every sub-section.
Future<void> showSubSections(
  BuildContext context,
  FeedCategory section,
  List<FeedCategory> children,
  int colorIndex,
  AppLanguage lang,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final scheme = theme.colorScheme;
      final s = S.of(lang);
      void go(FeedCategory c) {
        Navigator.of(sheetContext).pop();
        openCategory(context, c);
      }

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    _Badge(
                      icon: iconForCategory(section.id),
                      color: badgeColorFor(colorIndex),
                      size: 52,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.label(lang),
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            s.subSectionsN(children.length),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // "All <section>" — the parent itself
                _SheetRow(
                  icon: Icons.dashboard_rounded,
                  label: s.allOf(section.label(lang)),
                  emphasized: true,
                  onTap: () => go(section),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: children.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SheetRow(
                        icon: iconForCategory(children[i].id),
                        iconColor: badgeColorFor(colorIndex + i + 1),
                        label: children[i].label(lang),
                        onTap: () => go(children[i]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = emphasized ? scheme.primaryContainer : scheme.surfaceContainerHigh;
    final fg = emphasized ? scheme.onPrimaryContainer : scheme.onSurface;
    return Pressable(
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                if (iconColor != null)
                  _Badge(icon: icon, color: iconColor!, size: 36)
                else
                  Icon(icon, color: fg),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontWeight:
                          emphasized ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: fg.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The same squircle icon badge the list cards use.
class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.color, required this.size});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * 0.33),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      );
}

/// Tiles rise and fade in one after another when the grid appears.
class _Stagger extends StatelessWidget {
  const _Stagger({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const step = 45;
    const base = 280;
    final total = base + step * index;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(step * index / total, 1, curve: Curves.easeOutCubic),
      builder: (_, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: c),
      ),
      child: child,
    );
  }
}
