import 'package:flutter/material.dart';

import '../../../core/config/feeds.dart';
import '../../../core/localization/strings.dart';

/// A single expressive list card for a section/category (image3).
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.lang,
    required this.onTap,
    this.colorIndex = 0,
    this.subtitle,
    this.inset = false,
  });

  final FeedCategory category;
  final AppLanguage lang;
  final VoidCallback onTap;
  final int colorIndex;
  final String? subtitle;
  final bool inset;

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
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = S.of(lang);
    final label = category.label(lang);
    final badge = _badgeColors[colorIndex % _badgeColors.length];

    return Padding(
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
                  child: Text(
                    label.characters.first,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: inset ? 16 : 20,
                    ),
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
                      Text(
                        subtitle ??
                            (category.hasChildren
                                ? s.items(category.children.length)
                                : s.navLatest),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
