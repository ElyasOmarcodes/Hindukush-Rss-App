import 'package:flutter/material.dart';

import '../../../core/config/feeds.dart';
import '../../../core/util/dates.dart';
import '../../../data/models/article.dart';
import '../../../data/video.dart';
import '../../widgets/material_image.dart';
import '../../widgets/video_badge.dart';

/// The expressive top carousel of newest items (image2). Uses the framework's
/// [CarouselView] for the springy, snapping side-scroll.
class NewsCarousel extends StatelessWidget {
  const NewsCarousel({
    super.key,
    required this.articles,
    required this.lang,
    required this.onTap,
  });

  final List<Article> articles;
  final AppLanguage lang;
  final void Function(Article) onTap;

  @override
  Widget build(BuildContext context) {
    final items = articles.take(8).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 220,
      child: CarouselView(
        itemExtent: 320,
        shrinkExtent: 220,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        onTap: (i) => onTap(items[i]),
        children: [for (final a in items) _CarouselCard(article: a, lang: lang)],
      ),
    );
  }
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({required this.article, required this.lang});
  final Article article;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final video = VideoInfo.detect(article);
    return Stack(
      fit: StackFit.expand,
      children: [
        MaterialImage(
          url: video.thumbnail(article.imageUrl),
          fit: BoxFit.cover,
          borderRadius: BorderRadius.zero,
        ),
        if (video.isVideo) const VideoBadge(size: 46),
        // Legibility gradient.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.15),
                Colors.black.withValues(alpha: 0.78),
              ],
              stops: const [0.35, 0.6, 1],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (article.published != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    Dates.relative(article.published, lang),
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                article.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
