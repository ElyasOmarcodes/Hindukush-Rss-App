import 'package:flutter/material.dart';

import '../../core/config/feeds.dart';
import '../../core/localization/strings.dart';
import '../../data/models/article.dart';
import '../../services.dart';
import '../../state/app_state.dart';
import '../navigation/routes.dart';
import '../widgets/expressive_refresh.dart';
import '../widgets/network_states.dart';
import 'widgets/news_carousel.dart';
import 'widgets/section_grid.dart';
import 'widgets/section_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onSeeAll});

  /// Switches the app to the "Latest" tab (used by the carousel's See-all card).
  final VoidCallback? onSeeAll;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Article> _latest = [];
  bool _loading = true;
  bool _failed = false;
  AppLanguage? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = AppScope.of(context).language;
    if (_loadedFor != lang) {
      _loadedFor = lang;
      // Drop the previous language's articles immediately — otherwise they stay
      // on screen (and get merged with) the new language's results.
      _latest = const [];
      _loading = true;
      _load(lang);
    }
  }

  Future<void> _load(AppLanguage lang) async {
    // Show any cached items instantly (offline-friendly first paint).
    final cache = appRepository.cachedFor(kHomeFeed, lang);
    setState(() {
      if (_latest.isEmpty && cache.isNotEmpty) _latest = cache;
      _loading = _latest.isEmpty;
      _failed = false;
    });
    final result = await appRepository.loadLatest(
      lang,
      keepOffline: AppScope.read(context).keepOffline,
    );
    if (!mounted || _loadedFor != lang) return;
    setState(() {
      if (result.articles.isNotEmpty) _latest = result.articles;
      _loading = false;
      _failed = _latest.isEmpty && result.fromCache;
    });
  }

  Future<void> _refresh() async {
    final lang = AppScope.read(context).language;
    await _load(lang);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lang = app.language;
    final s = S.of(lang);
    final scheme = Theme.of(context).colorScheme;

    return ExpressiveRefresh(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                s.appName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
              ),
            ),
          ),
          if (_loading && _latest.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: LoadingWithSlowHint(),
              ),
            )
          else ...[
            // Only when there's nothing at all to show; the sections below
            // stay usable either way.
            if (_failed)
              SliverToBoxAdapter(
                child: ConnectionErrorView(onRetry: _refresh),
              ),
            SliverToBoxAdapter(
              child: NewsCarousel(
                articles: _latest,
                lang: lang,
                onTap: (a) => openPost(context, a),
                onSeeAll: widget.onSeeAll,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.sectionsTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    _LayoutToggle(
                      grid: app.homeGrid,
                      tooltip: app.homeGrid ? s.viewList : s.viewGrid,
                      onPressed: () => app.setHomeGrid(!app.homeGrid),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                // The height change between the two layouts is animated, and
                // the layouts themselves cross-fade with a slight zoom.
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 360),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topCenter,
                      children: [...previous, if (current != null) current],
                    ),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.96, end: 1.0).animate(anim),
                        alignment: Alignment.topCenter,
                        child: child,
                      ),
                    ),
                    child: app.homeGrid
                        ? SectionGrid(key: const ValueKey('grid'), lang: lang)
                        : SectionList(key: const ValueKey('list'), lang: lang),
                  ),
                ),
              ),
            ),
          ],
          // Clearance for the floating navigation bar.
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }
}

/// The list ⇄ grid switch: the icon spins and cross-fades into the other one.
class _LayoutToggle extends StatelessWidget {
  const _LayoutToggle({
    required this.grid,
    required this.tooltip,
    required this.onPressed,
  });

  final bool grid;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        transitionBuilder: (child, anim) => RotationTransition(
          turns: Tween(begin: 0.75, end: 1.0).animate(anim),
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: anim, child: child),
          ),
        ),
        child: Icon(
          // Shows the layout you'll switch *to*.
          grid ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
          key: ValueKey(grid),
        ),
      ),
    );
  }
}
