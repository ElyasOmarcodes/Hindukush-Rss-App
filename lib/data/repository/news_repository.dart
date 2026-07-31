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

/// Loads content with a resilient chain:
///   1. WordPress REST API   (reliable featured images + clean content)
///   2. RSS feed             (fallback when REST is unavailable)
///   3. Offline cache        (fallback when the network is unavailable)
class NewsRepository {
  NewsRepository({WpService? wp, RssService? rss, NewsDatabase? db})
      : _wp = wp ?? WpService(),
        _rss = rss ?? RssService(),
        _db = db ?? NewsDatabase.instance;

  final WpService _wp;
  final RssService _rss;
  final NewsDatabase _db;

  NewsDatabase get db => _db;

  List<Article> _visible(List<Article> list) =>
      list.where((a) => !_db.isHidden(a.id)).toList();

  Future<FeedResult> loadCategory(
    FeedCategory category,
    AppLanguage lang, {
    bool keepOffline = true,
  }) async {
    Object? lastError;

    // 1) REST API
    try {
      final articles = category.isHome
          ? await _wp.fetchLatest(lang, categoryId: category.id)
          : await _wp.fetchCategory(category, lang);
      if (articles.isNotEmpty) {
        final tagged = _tag(articles, lang);
        if (keepOffline) await _db.cacheArticles(tagged);
        return FeedResult(_visible(tagged));
      }
    } catch (e) {
      lastError = e;
    }

    // 2) RSS fallback
    try {
      final articles =
          await _rss.fetch(category.rssUrl(lang), categoryId: category.id);
      if (articles.isNotEmpty) {
        final tagged = _tag(articles, lang);
        if (keepOffline) await _db.cacheArticles(tagged);
        return FeedResult(_visible(tagged));
      }
    } catch (e) {
      lastError = e;
    }

    // 3) Offline cache — always scoped to the language being displayed.
    final cached = _db.cachedByCategory(category.id, lang.code);
    return FeedResult(_visible(cached), fromCache: true, error: lastError);
  }

  /// The single choke point that stamps every article with the language it was
  /// fetched from. Nothing reaches the cache or the UI without it.
  List<Article> _tag(List<Article> articles, AppLanguage lang) =>
      [for (final a in articles) a.copyWith(lang: lang.code)];

  Future<FeedResult> loadLatest(AppLanguage lang, {bool keepOffline = true}) =>
      loadCategory(kHomeFeed, lang, keepOffline: keepOffline);

  /// Synchronous cached snapshot (for instant first paint / offline).
  List<Article> cachedFor(FeedCategory category, AppLanguage lang) =>
      _visible(_db.cachedByCategory(category.id, lang.code));

  /// All cached articles for one language (used by in-app search).
  List<Article> allCached(AppLanguage lang) =>
      _visible(_db.allCached(lang.code));

  bool isHidden(String id) => _db.isHidden(id);
  Future<void> hideAll(Iterable<Article> articles) async {
    for (final a in articles) {
      await _db.hide(a.lang, a.id);
    }
  }

  List<Article> favorites(AppLanguage lang) => _db.favorites(lang.code);
  bool isFavorite(Article a) => _db.isFavorite(a);
  Future<void> toggleFavorite(Article a) => _db.toggleFavorite(a);
  bool isRead(String id) => _db.isRead(id);
  Future<void> markRead(String id) => _db.markRead(id);

  void dispose() {
    _wp.dispose();
    _rss.dispose();
  }
}
