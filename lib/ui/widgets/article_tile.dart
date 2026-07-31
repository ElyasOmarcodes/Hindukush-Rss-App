import 'package:flutter/material.dart';

import '../../core/config/feeds.dart';
import '../../core/util/dates.dart';
import '../../data/models/article.dart';
import '../../data/video.dart';
import 'material_image.dart';
import 'pressable.dart';
import 'video_badge.dart';

/// A modern Material 3 Expressive news card: a rounded surface container with a
/// large rounded thumbnail, a tonal time chip, the headline and a short excerpt.
/// Shared by the Latest / category lists and the Favorites tab.
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

    final cardColor = selected
        ? scheme.secondaryContainer
        : read
            ? scheme.surfaceContainerLow
            : scheme.surfaceContainerHigh;

    return Pressable(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
        child: Material(
          color: cardColor,
          borderRadius: BorderRadius.circular(26),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Thumb(
                    article: article,
                    video: video,
                    selected: selected,
                    selectionMode: selectionMode,
                    scheme: scheme,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TimeChip(
                          label: Dates.relative(article.published, lang),
                          read: read,
                          scheme: scheme,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          article.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            color: read
                                ? scheme.onSurfaceVariant
                                : scheme.onSurface,
                          ),
                        ),
                        if (article.summary.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            article.summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
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

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.article,
    required this.video,
    required this.selected,
    required this.selectionMode,
    required this.scheme,
  });

  final Article article;
  final VideoInfo video;
  final bool selected;
  final bool selectionMode;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MaterialImage(
          url: video.thumbnail(article.imageUrl),
          width: 96,
          height: 96,
          borderRadius: BorderRadius.circular(20),
        ),
        if (video.isVideo && !selectionMode)
          const Positioned.fill(child: VideoBadge(size: 32)),
        if (selectionMode)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              decoration: BoxDecoration(
                color: selected ? scheme.primary : Colors.black45,
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
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.read,
    required this.scheme,
  });

  final String label;
  final bool read;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 10, 3),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            read ? Icons.done_all_rounded : Icons.schedule_rounded,
            size: 13,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
