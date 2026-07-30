import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/feeds.dart';
import '../../core/localization/strings.dart';
import '../../core/util/dates.dart';
import '../../data/models/article.dart';
import '../../services.dart';
import '../../state/app_state.dart';
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

  void _copy(S s) {
    Clipboard.setData(ClipboardData(text: '${a.title}\n\n${a.link}'));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(s.copied)));
  }

  void _share() {
    Share.share('${a.title}\n${a.link}', subject: a.title);
  }

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

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header(context, lang, scheme)),
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
                    child: Text(
                      '${s.by} ${a.author}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
                  child: a.contentHtml.trim().isEmpty
                      ? Text(a.summary, style: bodyStyle)
                      : HtmlWidget(
                          a.contentHtml,
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
            ],
          ),
          // Bottom reading toolbar
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
                onQuickSettings: () => QuickSettingsSheet.show(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, AppLanguage lang, ColorScheme scheme) {
    final s = S.of(lang);
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: MaterialImage(
            url: a.imageUrl,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.zero,
            heroTag: 'img_${a.id}',
            openFullScreen: true,
          ),
        ),
        // Back button (no app bar per spec).
        Positioned(
          top: 8,
          left: 8,
          child: SafeArea(
            child: IconButton.filledTonal(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(
                lang.isRtl ? Icons.arrow_forward : Icons.arrow_back,
              ),
            ),
          ),
        ),
        // Open-in-browser
        Positioned(
          top: 8,
          right: 8,
          child: SafeArea(
            child: IconButton.filledTonal(
              tooltip: s.openInBrowser,
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_new_rounded),
            ),
          ),
        ),
        // Publish-date tag in a corner.
        if (a.published != null)
          Positioned(
            bottom: 10,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                Dates.absolute(a.published, lang),
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
