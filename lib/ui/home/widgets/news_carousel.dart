import 'package:flutter/material.dart';

import '../../../core/config/feeds.dart';
import '../../../core/util/dates.dart';
import '../../../data/models/article.dart';
import '../../../data/video.dart';
import '../../widgets/material_image.dart';
import '../../widgets/pressable.dart';
import '../../widgets/video_badge.dart';

/// The expressive top carousel of newest items. A [PageView] with peeking
/// neighbours + a gentle scale on the centred card gives a smooth Material 3
/// feel — the card width stays constant, so the title never reflows and the
/// image never "jumps" (the earlier CarouselView shrink artefacts are gone).
class NewsCarousel extends StatefulWidget {
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
  State<NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel> {
  final _controller = PageController(viewportFraction: 0.86);
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final p = _controller.page ?? 0;
      if ((p - _page).abs() > 0.001) setState(() => _page = p);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.articles.take(8).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 230,
          child: PageView.builder(
            controller: _controller,
            itemCount: items.length,
            padEnds: true,
            itemBuilder: (context, i) {
              final delta = (_page - i).abs();
              final scale = (1 - delta * 0.10).clamp(0.9, 1.0);
              return Transform.scale(
                scale: scale,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _CarouselCard(
                    article: items[i],
                    lang: widget.lang,
                    onTap: () => widget.onTap(items[i]),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _Dots(count: items.length, page: _page),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.page});
  final int count;
  final double page;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = page.round().clamp(0, count - 1);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == active ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == active
                  ? scheme.primary
                  : scheme.primary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({
    required this.article,
    required this.lang,
    required this.onTap,
  });
  final Article article;
  final AppLanguage lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final video = VideoInfo.detect(article);
    return Pressable(
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
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
          ),
        ),
      ),
    );
  }
}
