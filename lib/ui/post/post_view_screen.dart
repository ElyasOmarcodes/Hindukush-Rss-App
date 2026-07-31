import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/feeds.dart';
import '../../core/localization/strings.dart';
import '../../core/util/dates.dart';
import '../../core/util/html_text.dart';
import '../../data/models/article.dart';
import '../../data/video.dart';
import '../../services.dart';
import '../../state/app_state.dart';
import '../video/video_player_screen.dart';
import '../widgets/material_image.dart';
import 'widgets/find_in_article.dart';
import 'widgets/quick_settings_sheet.dart';
import 'widgets/reading_toolbar.dart';

class PostViewScreen extends StatefulWidget {
  const PostViewScreen({super.key, required this.article});

  final Article article;

  @override
  State<PostViewScreen> createState() => _PostViewScreenState();
}

class _PostViewScreenState extends State<PostViewScreen> {
  late bool _favorite = appRepository.isFavorite(widget.article);

  // --- in-article find ----------------------------------------------------
  final _findController = TextEditingController();
  final _findFocus = FocusNode();
  final _scrollController = ScrollController();
  bool _finding = false;
  String _query = '';
  List<FindMatch> _matches = const [];
  int _current = 0;

  /// Paragraph keys, so a match can be scrolled into view.
  final _paragraphKeys = <int, GlobalKey>{};

  late final List<String> _paragraphs = htmlToParagraphs(
    widget.article.contentHtml.trim().isEmpty
        ? widget.article.summary
        : widget.article.contentHtml,
  );

  @override
  void initState() {
    super.initState();
    appRepository.markRead(widget.article.id);
  }

  @override
  void dispose() {
    _findController.dispose();
    _findFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Article get a => widget.article;

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  /// Copies the headline and the full article text (not just the link).
  void _copy(S s) {
    final body = _paragraphs.join('\n\n');
    final buffer = StringBuffer()
      ..writeln(a.title)
      ..writeln();
    if (a.author != null && a.author!.trim().isNotEmpty) {
      buffer
        ..writeln('${s.by} ${a.author}')
        ..writeln();
    }
    if (body.isNotEmpty) {
      buffer
        ..writeln(body)
        ..writeln();
    }
    buffer.write(a.link);
    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    _snack(s.copied);
  }

  // --- find ---------------------------------------------------------------

  void _openFind() {
    setState(() => _finding = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _findFocus.requestFocus());
  }

  void _closeFind() {
    _findController.clear();
    setState(() {
      _finding = false;
      _query = '';
      _matches = const [];
      _current = 0;
    });
  }

  void _onQueryChanged(String q) {
    setState(() {
      _query = q;
      _matches = findMatches(_paragraphs, q);
      _current = 0;
    });
    if (_matches.isNotEmpty) _revealCurrent();
  }

  void _step(int delta) {
    if (_matches.isEmpty) return;
    setState(() {
      _current = (_current + delta) % _matches.length;
      if (_current < 0) _current += _matches.length;
    });
    _revealCurrent();
  }

  void _revealCurrent() {
    if (_matches.isEmpty) return;
    final key = _paragraphKeys[_matches[_current].paragraph];
    final ctx = key?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      alignment: 0.3,
    );
  }

  void _share() => Share.share('${a.title}\n${a.link}', subject: a.title);

  Future<void> _toggleFavorite() async {
    await appRepository.toggleFavorite(a);
    setState(() => _favorite = appRepository.isFavorite(a));
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

    return PopScope(
      canPop: !_finding,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeFind();
      },
      child: Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              if (_finding)
                _findAppBar(s, scheme)
              else
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
                      // Opens a find bar in the app bar; matches light up in
                      // the article body as the query is typed.
                      onPressed: _openFind,
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
                  // While finding, the body is rendered as plain paragraphs so
                  // matches can actually be highlighted and scrolled to.
                  child: _finding
                      ? _highlightedBody(bodyStyle, app.readingAlign, lang)
                      : _body.trim().isEmpty
                          ? Text(a.summary, style: bodyStyle)
                          : HtmlWidget(
                              _body,
                              key: ValueKey(
                                  '$align|${app.fontScale}|${app.lineHeight}'),
                              textStyle: bodyStyle,
                              customStylesBuilder: (_) =>
                                  {'text-align': align},
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
          if (!_finding)
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
      ),
    );
  }

  /// The app bar in find mode: a live search field plus a match counter and
  /// previous/next stepping.
  Widget _findAppBar(S s, ColorScheme scheme) {
    final hasQuery = _query.trim().isNotEmpty;
    return SliverAppBar(
      pinned: true,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _closeFind,
      ),
      title: TextField(
        controller: _findController,
        focusNode: _findFocus,
        onChanged: _onQueryChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: s.searchInArticle,
          border: InputBorder.none,
        ),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      actions: [
        if (hasQuery) ...[
          Center(
            child: Text(
              _matches.isEmpty ? '0' : '${_current + 1}/${_matches.length}',
              style: TextStyle(
                color: _matches.isEmpty
                    ? scheme.error
                    : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            tooltip: s.previousMatch,
            icon: const Icon(Icons.keyboard_arrow_up_rounded),
            onPressed: _matches.isEmpty ? null : () => _step(-1),
          ),
          IconButton(
            tooltip: s.nextMatch,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            onPressed: _matches.isEmpty ? null : () => _step(1),
          ),
        ],
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: hasQuery
              ? () {
                  _findController.clear();
                  _onQueryChanged('');
                }
              : _closeFind,
        ),
      ],
    );
  }

  /// The article body as plain paragraphs with every match highlighted.
  Widget _highlightedBody(
      TextStyle bodyStyle, ReadingAlign readingAlign, AppLanguage lang) {
    final textAlign = switch (readingAlign) {
      ReadingAlign.start => TextAlign.start,
      ReadingAlign.center => TextAlign.center,
      ReadingAlign.justify => TextAlign.justify,
    };
    final active = _matches.isEmpty ? null : _matches[_current];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _paragraphs.length; i++)
          Padding(
            key: _paragraphKeys[i] ??= GlobalKey(),
            padding: const EdgeInsets.only(bottom: 12),
            child: HighlightedParagraph(
              text: _paragraphs[i],
              matches: [
                for (final m in _matches)
                  if (m.paragraph == i) m,
              ],
              activeMatch: active,
              style: bodyStyle,
              textAlign: textAlign,
            ),
          ),
      ],
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
