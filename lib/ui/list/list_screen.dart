import 'package:flutter/material.dart';

import '../../core/config/feeds.dart';
import '../../core/localization/strings.dart';
import '../../data/models/article.dart';
import '../../services.dart';
import '../../state/app_state.dart';
import '../navigation/routes.dart';
import '../search/article_search.dart';
import '../widgets/article_tile.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/contained_loading_indicator.dart';
import '../widgets/edge_fade.dart';
import '../widgets/expressive_refresh.dart';

enum SortMode { newest, oldest, alpha, readFirst, unreadFirst }

/// Category / section list. Material search state, Sort-By menu, long-press
/// multi-select (delete-for-me / mark-read), pull-to-refresh, soft animations.
class ListScreen extends StatefulWidget {
  const ListScreen({super.key, required this.category, this.titleOverride});

  final FeedCategory category;
  final String? titleOverride;

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  List<Article> _all = [];
  bool _loading = true;
  bool _fromCache = false;
  AppLanguage? _loadedFor;
  SortMode _sort = SortMode.newest;

  bool _selectionMode = false;
  final _selected = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = AppScope.of(context).language;
    if (_loadedFor != lang) {
      _loadedFor = lang;
      // Drop the previous language's articles immediately — otherwise they stay
      // on screen (and get merged with) the new language's results.
      _all = const [];
      _loading = true;
      _selectionMode = false;
      _selected.clear();
      _load(lang);
    }
  }

  Future<void> _load(AppLanguage lang) async {
    final cache = appRepository.cachedFor(widget.category, lang);
    setState(() {
      if (_all.isEmpty && cache.isNotEmpty) _all = cache;
      _loading = _all.isEmpty;
    });
    final result = await appRepository.loadCategory(
      widget.category,
      lang,
      keepOffline: AppScope.read(context).keepOffline,
    );
    if (!mounted) return;
    setState(() {
      if (result.articles.isNotEmpty) _all = result.articles;
      _fromCache = result.fromCache;
      _loading = false;
    });
  }

  List<Article> get _sorted {
    final l = [..._all];
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    int read(Article a) => appRepository.isRead(a.id) ? 1 : 0;
    switch (_sort) {
      case SortMode.newest:
        l.sort((a, b) => (b.published ?? epoch).compareTo(a.published ?? epoch));
      case SortMode.oldest:
        l.sort((a, b) => (a.published ?? epoch).compareTo(b.published ?? epoch));
      case SortMode.alpha:
        l.sort((a, b) => a.title.compareTo(b.title));
      case SortMode.readFirst:
        l.sort((a, b) => read(b).compareTo(read(a)));
      case SortMode.unreadFirst:
        l.sort((a, b) => read(a).compareTo(read(b)));
    }
    return l;
  }

  // --- selection ----------------------------------------------------------

  void _enterSelection(String id) => setState(() {
        _selectionMode = true;
        _selected.add(id);
      });

  void _toggle(String id) => setState(() {
        if (!_selected.remove(id)) _selected.add(id);
        if (_selected.isEmpty) _selectionMode = false;
      });

  void _exitSelection() => setState(() {
        _selectionMode = false;
        _selected.clear();
      });

  Future<void> _deleteSelected(S s) async {
    final ok = await showConfirmDialog(
      context,
      icon: Icons.delete_outline_rounded,
      title: s.delete,
      message: s.deleteMsg,
      confirmLabel: s.delete,
      danger: true,
    );
    if (!ok) return;
    await appRepository.hideAll(
      _all.where((a) => _selected.contains(a.id)),
    );
    final lang = AppScope.read(context).language;
    _exitSelection();
    await _load(lang);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.deletedN)));
    }
  }

  Future<void> _markReadSelected() async {
    for (final id in _selected) {
      await appRepository.markRead(id);
    }
    _exitSelection();
  }

  Future<void> _showSortMenu(S s) async {
    final options = <(SortMode, String, IconData)>[
      (SortMode.newest, s.sortNewest, Icons.schedule_rounded),
      (SortMode.oldest, s.sortOldest, Icons.history_rounded),
      (SortMode.alpha, s.sortAlpha, Icons.sort_by_alpha_rounded),
      (SortMode.readFirst, s.sortReadFirst, Icons.done_all_rounded),
      (SortMode.unreadFirst, s.sortUnreadFirst, Icons.mark_email_unread_outlined),
    ];
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(children: [
                const Icon(Icons.sort_rounded),
                const SizedBox(width: 10),
                Text(s.sortBy,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ]),
            ),
            for (final (mode, label, icon) in options)
              RadioListTile<SortMode>(
                value: mode,
                groupValue: _sort,
                onChanged: (v) {
                  if (v != null) setState(() => _sort = v);
                  Navigator.of(context).pop();
                },
                title: Text(label),
                secondary: Icon(icon),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppScope.of(context).language;
    final s = S.of(lang);
    final scheme = Theme.of(context).colorScheme;
    final items = _sorted;

    return PopScope(
      canPop: !_selectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitSelection();
      },
      child: Scaffold(
        body: ExpressiveRefresh(
          onRefresh: () => _load(lang),
          topInset: 72,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _appBar(context, s, scheme, lang),
              const SliverFadeUnderAppBar(),
              if (_fromCache && !_loading)
                SliverToBoxAdapter(child: _offlineBanner(s, scheme)),
              if (_loading && items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: CenteredLoading(),
                )
              else if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _empty(s, scheme),
                )
              else
                SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final a = items[i];
                    return _AnimatedItem(
                      index: i,
                      child: ArticleTile(
                        article: a,
                        lang: lang,
                        read: appRepository.isRead(a.id),
                        selectionMode: _selectionMode,
                        selected: _selected.contains(a.id),
                        onLongPress: () => _enterSelection(a.id),
                        onTap: () => _selectionMode
                            ? _toggle(a.id)
                            : openPost(context, a),
                      ),
                    );
                  },
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appBar(BuildContext context, S s, ColorScheme scheme, AppLanguage lang) {
    if (_selectionMode) {
      return SliverAppBar.medium(
        pinned: true,
        backgroundColor: scheme.secondaryContainer,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _exitSelection,
        ),
        title: Text(s.selectedN(_selected.length)),
        actions: [
          IconButton(
            tooltip: s.markRead,
            icon: const Icon(Icons.done_all_rounded),
            onPressed: _markReadSelected,
          ),
          IconButton(
            tooltip: s.delete,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _deleteSelected(s),
          ),
          const SizedBox(width: 4),
        ],
      );
    }
    return SliverAppBar.large(
      pinned: true,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(widget.titleOverride ?? widget.category.label(lang)),
      actions: [
        IconButton.filledTonal(
          icon: const Icon(Icons.search_rounded),
          tooltip: s.search,
          onPressed: () => showSearch(
            context: context,
            delegate: ArticleSearchDelegate(lang, scope: _sorted),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          icon: const Icon(Icons.sort_rounded),
          tooltip: s.sortBy,
          onPressed: () => _showSortMenu(s),
        ),
        const SizedBox(width: 10),
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
              child: Text(s.offline,
                  style: TextStyle(color: scheme.onTertiaryContainer)),
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
            Text(s.empty, style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      );
}

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
