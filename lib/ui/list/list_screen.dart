import 'package:flutter/material.dart';

import '../../core/config/feeds.dart';
import '../../core/localization/strings.dart';
import '../../data/models/article.dart';
import '../../services.dart';
import '../../state/app_state.dart';
import '../navigation/routes.dart';
import '../widgets/article_tile.dart';
import '../widgets/contained_loading_indicator.dart';

/// Category / section list. Uses a Material "search app bar" whose background
/// matches the screen (image4), pull-to-refresh with a contained loading
/// indicator, and soft animated list items.
class ListScreen extends StatefulWidget {
  const ListScreen({super.key, required this.category, this.titleOverride});

  final FeedCategory category;

  /// When set, shown instead of the category label (used by the "Latest" tab).
  final String? titleOverride;

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  List<Article> _all = [];
  bool _loading = true;
  bool _fromCache = false;
  AppLanguage? _loadedFor;

  bool _searching = false;
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = AppScope.of(context).language;
    if (_loadedFor != lang) {
      _loadedFor = lang;
      _load(lang);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load(AppLanguage lang) async {
    setState(() => _loading = true);
    final result = await appRepository.loadCategory(
      widget.category,
      lang,
      keepOffline: AppScope.read(context).keepOffline,
    );
    if (!mounted) return;
    setState(() {
      _all = result.articles;
      _fromCache = result.fromCache;
      _loading = false;
    });
  }

  List<Article> get _visible {
    if (_query.isEmpty) return _all;
    final q = _query.toLowerCase();
    return _all
        .where((a) =>
            a.title.toLowerCase().contains(q) ||
            a.summary.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lang = app.language;
    final s = S.of(lang);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _load(lang),
        displacement: 60,
        color: scheme.onSecondaryContainer,
        backgroundColor: scheme.secondaryContainer,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _appBar(context, s, scheme),
            if (_fromCache && !_loading)
              SliverToBoxAdapter(child: _offlineBanner(s, scheme)),
            if (_loading && _all.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: CenteredLoading(),
              )
            else if (_visible.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _empty(s, scheme),
              )
            else
              SliverList.separated(
                itemCount: _visible.length,
                separatorBuilder: (_, __) => const Divider(indent: 114),
                itemBuilder: (context, i) {
                  final a = _visible[i];
                  return _AnimatedItem(
                    index: i,
                    child: ArticleTile(
                      article: a,
                      lang: lang,
                      read: appRepository.isRead(a.id),
                      onTap: () => openPost(context, a),
                    ),
                  );
                },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _appBar(BuildContext context, S s, ColorScheme scheme) {
    return SliverAppBar.medium(
      pinned: true,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      title: _searching
          ? TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: s.search,
                border: InputBorder.none,
              ),
            )
          : Text(widget.titleOverride ??
              widget.category.label(AppScope.of(context).language)),
      actions: [
        IconButton(
          icon: Icon(_searching ? Icons.close : Icons.search),
          tooltip: s.search,
          onPressed: () => setState(() {
            _searching = !_searching;
            if (!_searching) {
              _query = '';
              _searchCtrl.clear();
            }
          }),
        ),
        if (!_searching)
          IconButton(
            icon: const Icon(Icons.today_outlined),
            onPressed: () => _load(AppScope.read(context).language),
          ),
      ],
    );
  }

  Widget _offlineBanner(S s, ColorScheme scheme) => Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 18, color: scheme.onTertiaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s.offline,
                style: TextStyle(color: scheme.onTertiaryContainer),
              ),
            ),
          ],
        ),
      );

  Widget _empty(S s, ColorScheme scheme) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 56, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(s.empty,
                style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      );
}

/// Staggered fade/slide-in for list items.
class _AnimatedItem extends StatefulWidget {
  const _AnimatedItem({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_AnimatedItem> createState() => _AnimatedItemState();
}

class _AnimatedItemState extends State<_AnimatedItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 40 * (widget.index % 8)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curve),
        child: widget.child,
      ),
    );
  }
}
