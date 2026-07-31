import 'package:flutter/material.dart';

import '../../../core/config/feeds.dart';
import '../../../core/localization/strings.dart';
import '../../../core/util/dates.dart';
import '../../../data/models/article.dart';
import '../../../data/video.dart';
import '../../widgets/material_image.dart';
import '../../widgets/video_badge.dart';

/// The Material 3 "hero" carousel: one large item with a peek of the next
/// (two items on screen at a time). Content is laid out at the large width in
/// an [OverflowBox] and clipped as items resize, so the image crops gracefully
/// and the title never reflows. The final item is a "See all" card.
class NewsCarousel extends StatelessWidget {
  const NewsCarousel({
    super.key,
    required this.articles,
    required this.lang,
    required this.onTap,
    this.onSeeAll,
  });

  final List<Article> articles;
  final AppLanguage lang;
  final void Function(Article) onTap;
  final VoidCallback? onSeeAll;

  // Large item + a peek of the next => two items visible.
  static const _weights = [3, 1];

  @override
  Widget build(BuildContext context) {
    final items = articles.take(8).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final showSeeAll = onSeeAll != null;
    final count = items.length + (showSeeAll ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: 226,
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
              onTap: (i) {
                if (i < items.length) {
                  onTap(items[i]);
                } else {
                  onSeeAll?.call();
                }
              },
              children: [
                for (final a in items)
                  OverflowBox(
                    minWidth: largeW,
                    maxWidth: largeW,
                    alignment: AlignmentDirectional.centerStart,
                    child: _CardContent(article: a, lang: lang),
                  ),
                if (showSeeAll)
                  OverflowBox(
                    minWidth: largeW,
                    maxWidth: largeW,
                    alignment: AlignmentDirectional.centerStart,
                    child: _SeeAllContent(lang: lang),
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
        // A stronger, taller legibility gradient at the bottom.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.92),
              ],
              stops: const [0.25, 0.55, 1],
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
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    Dates.relative(article.published, lang),
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 7),
              Text(
                article.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
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

class _SeeAllContent extends StatelessWidget {
  const _SeeAllContent({required this.lang});
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(lang);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward_rounded,
                  color: scheme.onPrimary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              s.seeAll,
              style: TextStyle(
                color: scheme.onPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
