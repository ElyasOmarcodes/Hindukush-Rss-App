import 'package:flutter/material.dart';

import '../../../core/config/feeds.dart';
import '../../widgets/pressable.dart';

/// A topic icon for each section/category id.
IconData iconForCategory(String id) => switch (id) {
      'home' => Icons.home_rounded,
      'news' => Icons.newspaper_rounded,
      'news-picks' => Icons.fiber_new_rounded,
      'afghanistan' => Icons.flag_rounded,
      'region' => Icons.travel_explore_rounded,
      'middle-east' => Icons.mosque_rounded,
      'world' => Icons.public_rounded,
      'comments' => Icons.forum_rounded,
      'articles' => Icons.article_rounded,
      'religious' => Icons.menu_book_rounded,
      'important' => Icons.priority_high_rounded,
      'political' => Icons.gavel_rounded,
      'selected' => Icons.star_rounded,
      'world-media' => Icons.podcasts_rounded,
      'raz' => Icons.lock_rounded,
      'tabyin' => Icons.lightbulb_rounded,
      'dark-faces' => Icons.theater_comedy_rounded,
      'videos' => Icons.play_circle_rounded,
      _ => Icons.label_rounded,
    };

/// A single expressive section/category card (image3), now with a topic icon,
/// a soft press animation and an optional expander for sub-items.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.lang,
    required this.onTap,
    this.colorIndex = 0,
    this.subtitle,
    this.inset = false,
    this.expandable = false,
    this.expanded = false,
    this.onToggleExpand,
  });

  final FeedCategory category;
  final AppLanguage lang;
  final VoidCallback onTap;
  final int colorIndex;
  final String? subtitle;
  final bool inset;
  final bool expandable;
  final bool expanded;
  final VoidCallback? onToggleExpand;

  static const _badgeColors = [
    Color(0xFF9C6ADE),
    Color(0xFF6C7BEF),
    Color(0xFFD46AD4),
    Color(0xFF4CAF93),
    Color(0xFFE08A4B),
    Color(0xFF5C9CE0),
    Color(0xFFCE5B7C),
    Color(0xFF7E8B3A),
    Color(0xFF8E6AD0),
    Color(0xFF4BA6B8),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = category.label(lang);
    final badge = _badgeColors[colorIndex % _badgeColors.length];

    return Pressable(
      child: Padding(
        padding: EdgeInsets.only(bottom: 10, left: inset ? 20 : 0),
        child: Material(
          color: inset ? scheme.surfaceContainer : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(inset ? 20 : 26),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: inset ? 12 : 16,
              ),
              child: Row(
                children: [
                  Container(
                    width: inset ? 40 : 52,
                    height: inset ? 40 : 52,
                    decoration: BoxDecoration(
                      color: badge,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      iconForCategory(category.id),
                      color: Colors.white,
                      size: inset ? 20 : 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (expandable)
                    _ExpandButton(
                      expanded: expanded,
                      onTap: onToggleExpand,
                    )
                  else
                    Icon(Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandButton extends StatelessWidget {
  const _ExpandButton({required this.expanded, this.onTap});
  final bool expanded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: expanded ? scheme.secondaryContainer : scheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: AnimatedRotation(
            turns: expanded ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: Icon(Icons.expand_more_rounded,
                color: expanded
                    ? scheme.onSecondaryContainer
                    : scheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
