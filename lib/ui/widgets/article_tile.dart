import 'package:flutter/material.dart';

import '../../core/config/feeds.dart';
import '../../core/util/dates.dart';
import '../../data/models/article.dart';
import '../../data/video.dart';
import 'material_image.dart';
import 'pressable.dart';
import 'video_badge.dart';

/// A list row: thumbnail + title + one-line excerpt + date, matching image3.
class ArticleTile extends StatelessWidget {
  const ArticleTile({
    super.key,
    required this.article,
    required this.lang,
    required this.onTap,
    this.onLongPress,
    this.read = false,
    this.selected = false,
    this.selectionMode = false,
  });

  final Article article;
  final AppLanguage lang;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool read;
  final bool selected;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final video = VideoInfo.detect(article);
    return Pressable(
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        child: InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                MaterialImage(
                  url: video.thumbnail(article.imageUrl),
                  width: 88,
                  height: 88,
                  borderRadius: BorderRadius.circular(18),
                ),
                if (video.isVideo && !selectionMode)
                  const Positioned.fill(child: VideoBadge(size: 30)),
                if (selectionMode)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected ? scheme.primary : Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
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
      ),
    );
  }
}
