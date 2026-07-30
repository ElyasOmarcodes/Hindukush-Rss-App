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

  Future<FeedResult> loadCategory(
    FeedCategory category,
    AppLanguage lang, {
    bool keepOffline = true,
  }) async {
    // 1) REST API
    try {
      final articles = category.isHome
          ? await _wp.fetchLatest(lang, categoryId: category.id)
          : await _wp.fetchCategory(category, lang);
      if (articles.isNotEmpty) {
        if (keepOffline) await _db.cacheArticles(articles);
        return FeedResult(articles);
      }
    } catch (_) {
      // fall through to RSS
    }

    // 2) RSS fallback
    try {
      final articles =
          await _rss.fetch(category.rssUrl(lang), categoryId: category.id);
      if (articles.isNotEmpty) {
        if (keepOffline) await _db.cacheArticles(articles);
        return FeedResult(articles);
      }
    } catch (_) {
      // fall through to cache
    }

    // 3) Offline cache
    final cached = _db.cachedByCategory(category.id);
    return FeedResult(cached, fromCache: true);
  }

  Future<FeedResult> loadLatest(AppLanguage lang, {bool keepOffline = true}) =>
      loadCategory(kHomeFeed, lang, keepOffline: keepOffline);

  /// Synchronous cached snapshot (for instant first paint / offline).
  List<Article> cachedFor(FeedCategory category) =>
      _db.cachedByCategory(category.id);

  List<Article> favorites() => _db.favorites();
  bool isFavorite(String id) => _db.isFavorite(id);
  Future<void> toggleFavorite(Article a) => _db.toggleFavorite(a);
  bool isRead(String id) => _db.isRead(id);
  Future<void> markRead(String id) => _db.markRead(id);

  void dispose() {
    _wp.dispose();
    _rss.dispose();
  }
}
