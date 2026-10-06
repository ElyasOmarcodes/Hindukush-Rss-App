import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/config/feeds.dart';
import '../db/database.dart';
import '../models/article.dart';
import '../rss/rss_service.dart';
import '../wp/wp_service.dart';

/// Result of a feed load, carrying whether the data came from the network or
/// the offline cache (so the UI can show an "offline" hint).
class FeedResult {
  FeedResult(this.articles, {this.fromCache = false, this.error});
  final List<Article> articles;
  final bool fromCache;
  final Object? error;
}

enum _Source { rest, rss }

/// Loads content with a resilient chain:
///   1. WordPress REST API   (light list, featured images)
///   2. RSS feed             (fallback when REST is unavailable)
///   3. Offline cache        (fallback when the network is unavailable)
///
/// Whichever of REST/RSS worked last for a site is tried *first* next time, so
/// a network that blocks one of them only pays the failover cost once.
class NewsRepository {
  NewsRepository({WpService? wp, RssService? rss, NewsDatabase? db})
      : _db = db ?? NewsDatabase.instance,
        _rss = rss ?? RssService() {
    _wp = wp ?? WpService(db: _db);
  }

  late final WpService _wp;
  final RssService _rss;
  final NewsDatabase _db;

  NewsDatabase get db => _db;

  /// Bumped whenever cached content or read/favorite state changes, so badges
  /// and lists can refresh without polling.
  final ValueNotifier<int> changes = ValueNotifier(0);
  void _changed() => changes.value++;

  final Map<AppLanguage, _Source> _preferred = {};

  List<Article> _visible(List<Article> list) =>
      list.where((a) => !_db.isHidden(a.id)).toList();

  Future<FeedResult> loadCategory(
    FeedCategory category,
    AppLanguage lang, {
    bool keepOffline = true,
  }) async {
    Object? lastError;
    final order = _preferred[lang] == _Source.rss
        ? const [_Source.rss, _Source.rest]
        : const [_Source.rest, _Source.rss];

    for (final source in order) {
      try {
        final articles = switch (source) {
          _Source.rest => category.isHome
              ? await _wp.fetchLatest(lang, categoryId: category.id)
              : await _wp.fetchCategory(category, lang),
          _Source.rss =>
            await _rss.fetch(category.rssUrl(lang), categoryId: category.id),
        };
        if (articles.isEmpty) continue;
        _preferred[lang] = source;
        var tagged = _tag(articles, lang);
        if (keepOffline) {
          await _db.cacheArticles(tagged);
          // Read back the merged rows so bodies / reading times we already
          // have aren't lost just because the list response omits them.
          tagged = [for (final a in tagged) _db.cached(a.lang, a.id) ?? a];
          _changed();
          _prefetchBodies(tagged);
        }
        return FeedResult(_visible(tagged));
      } catch (e) {
        lastError = e;
      }
    }

    // Offline cache — always scoped to the language being displayed.
    final cached = _db.cachedByCategory(category.id, lang.code);
    return FeedResult(_visible(cached), fromCache: true, error: lastError);
  }

  /// The single choke point that stamps every article with the language it was
  /// fetched from. Nothing reaches the cache or the UI without it.
  List<Article> _tag(List<Article> articles, AppLanguage lang) =>
      [for (final a in articles) a.copyWith(lang: lang.code)];

  Future<FeedResult> loadLatest(AppLanguage lang, {bool keepOffline = true}) =>
      loadCategory(kHomeFeed, lang, keepOffline: keepOffline);

  // --- article bodies ------------------------------------------------------

  /// Returns [a] with its full body, from the cache when possible, otherwise
  /// from the network. Throws if it can't be fetched.
  Future<Article> loadFullContent(Article a) async {
    if (a.hasContent) return a;
    final cached = _db.cached(a.lang, a.id);
    if (cached != null && cached.hasContent) return cached;
    if (a.wpId == null) return a; // RSS rows carry their body already

    final lang = AppLanguageX.fromCode(a.lang);
    final full = await _wp.fetchContent(lang, a.wpId!);
    final updated = a.copyWith(contentHtml: full.content, author: full.author);
    await _db.cacheArticles([updated]);
    await _db.refreshFavorite(updated);
    _changed();
    return _db.cached(a.lang, a.id) ?? updated;
  }

  bool _prefetching = false;

  /// Quietly fetches the bodies of the first few rows, one at a time, so the
  /// most likely reads open instantly and work offline. It waits a moment
  /// first so it never competes with the list the user is waiting for.
  void _prefetchBodies(List<Article> rows) {
    if (_prefetching) return;
    final todo =
        rows.where((a) => !a.hasContent && a.wpId != null).take(5).toList();
    if (todo.isEmpty) return;
    _prefetching = true;
    unawaited(() async {
      try {
        await Future<void>.delayed(const Duration(seconds: 2));
        for (final a in todo) {
          try {
            await loadFullContent(a);
          } catch (_) {
            break; // the network is struggling; don't keep pushing
          }
        }
      } finally {
        _prefetching = false;
      }
    }());
  }

  // --- cache views ---------------------------------------------------------

  /// Synchronous cached snapshot (for instant first paint / offline).
  List<Article> cachedFor(FeedCategory category, AppLanguage lang) =>
      _visible(_db.cachedByCategory(category.id, lang.code));

  /// All cached articles for one language (used by in-app search).
  List<Article> allCached(AppLanguage lang) =>
      _visible(_db.allCached(lang.code));

  /// Refreshes rows from the cache (picks up bodies/reading times that the
  /// background prefetch has filled in since the list was shown).
  List<Article> refreshed(List<Article> rows) =>
      [for (final a in rows) _db.cached(a.lang, a.id) ?? a];

  /// Unread items among the newest cached "Latest" rows — the nav badge.
  int unreadLatest(AppLanguage lang) => cachedFor(kHomeFeed, lang)
      .take(30)
      .where((a) => !_db.isRead(a.id))
      .length;

  // --- user state ----------------------------------------------------------

  bool isHidden(String id) => _db.isHidden(id);
  Future<void> hideAll(Iterable<Article> articles) async {
    for (final a in articles) {
      await _db.hide(a.lang, a.id);
    }
    _changed();
  }

  List<Article> favorites(AppLanguage lang) => _db.favorites(lang.code);
  bool isFavorite(Article a) => _db.isFavorite(a);
  Future<void> toggleFavorite(Article a) async {
    await _db.toggleFavorite(a);
    _changed();
  }

  bool isRead(String id) => _db.isRead(id);
  Future<void> markRead(String id) async {
    if (_db.isRead(id)) return;
    await _db.markRead(id);
    _changed();
  }

  Future<void> markAllRead(Iterable<String> ids) async {
    await _db.markAllRead(ids);
    _changed();
  }

  void dispose() {
    _wp.dispose();
    _rss.dispose();
    changes.dispose();
  }
}
