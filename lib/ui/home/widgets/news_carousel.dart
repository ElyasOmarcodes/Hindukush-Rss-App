import 'package:flutter/material.dart';

import '../../../core/config/feeds.dart';
import '../../../core/util/dates.dart';
import '../../../data/models/article.dart';
import '../../../data/video.dart';
import '../../widgets/material_image.dart';
import '../../widgets/video_badge.dart';

/// The Material 3 "multi-browse" carousel (per the official guidelines): a large
/// leading item with smaller peeking items that resize smoothly as you scroll.
///
/// Each card's content is laid out at the *large* width inside an [OverflowBox]
/// and simply clipped as the item shrinks — so the image crops gracefully and
/// the title never reflows (fixing the earlier "jumpy" behaviour).
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

  static const _weights = [3, 2, 1];

  @override
  Widget build(BuildContext context) {
    final items = articles.take(8).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: 224,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final total = _weights.reduce((a, b) => a + b);
            final largeW = constraints.maxWidth * _weights.first / total;
            return CarouselView.weighted(
              flexWeights: _weights,
              itemSnapping: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              onTap: (i) => onTap(items[i]),
              children: [
                for (final a in items)
                  OverflowBox(
                    minWidth: largeW,
                    maxWidth: largeW,
                    alignment: AlignmentDirectional.centerStart,
                    child: _CardContent(article: a, lang: lang),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({required this.article, required this.lang});
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
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.16),
                Colors.black.withValues(alpha: 0.80),
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
