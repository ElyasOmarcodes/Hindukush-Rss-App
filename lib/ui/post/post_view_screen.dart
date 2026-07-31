import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/feeds.dart';
import '../../core/localization/strings.dart';
import '../../core/util/dates.dart';
import '../../data/models/article.dart';
import '../../data/video.dart';
import '../../services.dart';
import '../../state/app_state.dart';
import '../search/article_text_search.dart';
import '../video/video_player_screen.dart';
import '../widgets/material_image.dart';
import 'widgets/quick_settings_sheet.dart';
import 'widgets/reading_toolbar.dart';

class PostViewScreen extends StatefulWidget {
  const PostViewScreen({super.key, required this.article});

  final Article article;

  @override
  State<PostViewScreen> createState() => _PostViewScreenState();
}

class _PostViewScreenState extends State<PostViewScreen> {
  late bool _favorite = appRepository.isFavorite(widget.article.id);

  @override
  void initState() {
    super.initState();
    appRepository.markRead(widget.article.id);
  }

  Article get a => widget.article;

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  void _copy(S s) {
    Clipboard.setData(ClipboardData(text: '${a.title}\n\n${a.link}'));
    _snack(s.copied);
  }

  void _share() => Share.share('${a.title}\n${a.link}', subject: a.title);

  Future<void> _toggleFavorite() async {
    await appRepository.toggleFavorite(a);
    setState(() => _favorite = appRepository.isFavorite(a.id));
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.tryParse(a.link);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _playVideo(VideoInfo video) async {
    if (video.mp4Url != null) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(url: video.mp4Url!, title: a.title),
      ));
    } else if (video.youtubeWatchUrl != null) {
      await launchUrl(Uri.parse(video.youtubeWatchUrl!),
          mode: LaunchMode.externalApplication);
    }
  }

  /// The featured image is shown in the header; strip a duplicate leading image
  /// from the body so it doesn't appear twice.
  String get _body {
    if (a.imageUrl == null) return a.contentHtml;
    var h = a.contentHtml;
    final fig = RegExp(r'<figure[^>]*>.*?</figure>',
        dotAll: true, caseSensitive: false);
    final mf = fig.firstMatch(h);
    if (mf != null && mf.start < 60) {
      return h.replaceRange(mf.start, mf.end, '');
    }
    final img = RegExp(r'<img[^>]*>', caseSensitive: false);
    final mi = img.firstMatch(h);
    if (mi != null && mi.start < 60) {
      return h.replaceRange(mi.start, mi.end, '');
    }
    return h;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lang = app.language;
    final s = S.of(lang);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final align = switch (app.readingAlign) {
      ReadingAlign.start => lang.isRtl ? 'right' : 'left',
      ReadingAlign.center => 'center',
      ReadingAlign.justify => 'justify',
    };
    final bodyStyle = theme.textTheme.bodyLarge!.copyWith(
      fontSize: (theme.textTheme.bodyLarge!.fontSize ?? 16) * app.fontScale,
      height: app.lineHeight,
      color: scheme.onSurface,
    );
    final video = VideoInfo.detect(a);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: scheme.surface,
                surfaceTintColor: Colors.transparent,
                leading: Padding(
                  padding: const EdgeInsets.all(6),
                  child: IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: IconButton.filledTonal(
                      tooltip: s.searchInArticle,
                      // Searches the words of *this* article, not the feed.
                      onPressed: () => showSearch(
                        context: context,
                        delegate: ArticleTextSearchDelegate(
                          lang: lang,
                          title: a.title,
                          html: a.contentHtml.trim().isEmpty
                              ? a.summary
                              : a.contentHtml,
                        ),
                      ),
                      icon: const Icon(Icons.find_in_page_rounded),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: _Header(
                    article: a,
                    lang: lang,
                    thumbnailUrl: video.thumbnail(a.imageUrl),
                    onPlay: video.isVideo ? () => _playVideo(video) : null,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                  child: Text(
                    a.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
              if (a.author != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
                    child: Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 15, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(
                          '${s.by} ${a.author}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: _body.trim().isEmpty
                      ? Text(a.summary, style: bodyStyle)
                      : HtmlWidget(
                          _body,
                          key: ValueKey(
                              '$align|${app.fontScale}|${app.lineHeight}'),
                          textStyle: bodyStyle,
                          customStylesBuilder: (_) => {'text-align': align},
                          onTapUrl: (url) async {
                            final uri = Uri.tryParse(url);
                            if (uri != null) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                            return true;
                          },
                        ),
                ),
              ),
              // Read-on-website call to action.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
                  child: _ReadOnSiteCard(
                    label: s.readOnSite,
                    onTap: _openInBrowser,
                    scheme: scheme,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: ReadingToolbar(
                isFavorite: _favorite,
                onCopy: () => _copy(s),
                onShare: _share,
                onToggleFavorite: _toggleFavorite,
                onOpenWebsite: _openInBrowser,
                onQuickSettings: () => QuickSettingsSheet.show(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.article,
    required this.lang,
    required this.thumbnailUrl,
    this.onPlay,
  });
  final Article article;
  final AppLanguage lang;
  final String? thumbnailUrl;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        MaterialImage(
          url: thumbnailUrl,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.zero,
          heroTag: 'img_${article.id}',
          openFullScreen: onPlay == null,
        ),
        if (onPlay != null)
          Center(
            child: GestureDetector(
              onTap: onPlay,
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Icon(Icons.play_arrow_rounded,
                    color: scheme.onPrimary, size: 40),
              ),
            ),
          ),
        // Top scrim so the back/search buttons stay legible over any image.
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  Colors.black.withValues(alpha: 0.28),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        if (article.published != null)
          Positioned(
            bottom: 12,
            right: 14,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                Dates.absolute(article.published, lang),
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReadOnSiteCard extends StatelessWidget {
  const _ReadOnSiteCard({
    required this.label,
    required this.onTap,
    required this.scheme,
  });
  final String label;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.open_in_new_rounded,
                    color: scheme.onPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: scheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}
