import 'package:flutter/material.dart';

import '../../core/config/feeds.dart';
import '../../core/util/dates.dart';
import '../../data/models/article.dart';
import 'material_image.dart';
import 'pressable.dart';

/// A list row: thumbnail + title + one-line excerpt + date, matching image3.
class ArticleTile extends StatelessWidget {
  const ArticleTile({
    super.key,
    required this.article,
    required this.lang,
    required this.onTap,
    this.read = false,
  });

  final Article article;
  final AppLanguage lang;
  final VoidCallback onTap;
  final bool read;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Pressable(
      child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MaterialImage(
              url: article.imageUrl,
              width: 88,
              height: 88,
              borderRadius: BorderRadius.circular(18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: read
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                    ),
                  ),
                  if (article.summary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      article.summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 13, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        Dates.relative(article.published, lang),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (read) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.done_all,
                            size: 13, color: scheme.primary),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
