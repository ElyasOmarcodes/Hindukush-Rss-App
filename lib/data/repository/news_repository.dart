import '../../core/config/feeds.dart';
import '../db/database.dart';
import '../models/article.dart';
import '../rss/rss_service.dart';

/// Result of a feed load, carrying whether the data came from the network or
/// from the offline cache (so the UI can show an "offline" hint).
class FeedResult {
  FeedResult(this.articles, {this.fromCache = false, this.error});
  final List<Article> articles;
  final bool fromCache;
  final Object? error;
}

class NewsRepository {
  NewsRepository({RssService? service, NewsDatabase? db})
      : _service = service ?? RssService(),
        _db = db ?? NewsDatabase.instance;

  final RssService _service;
  final NewsDatabase _db;

  NewsDatabase get db => _db;

  /// Loads a category feed. Tries the network first; on failure falls back to
  /// whatever is cached for that category.
  Future<FeedResult> loadCategory(
    FeedCategory category,
    AppLanguage lang, {
    bool keepOffline = true,
  }) async {
    try {
      final url = category.feedUrl(lang);
      final articles = await _service.fetch(url, categoryId: category.id);
      if (keepOffline && articles.isNotEmpty) {
        await _db.cacheArticles(articles);
      }
      if (articles.isEmpty) {
        final cached = _db.cachedByCategory(category.id);
        if (cached.isNotEmpty) return FeedResult(cached, fromCache: true);
      }
      return FeedResult(articles);
    } catch (e) {
      final cached = _db.cachedByCategory(category.id);
      return FeedResult(cached, fromCache: true, error: e);
    }
  }

  /// The "Latest" stream = the home feed.
  Future<FeedResult> loadLatest(AppLanguage lang, {bool keepOffline = true}) =>
      loadCategory(kHomeFeed, lang, keepOffline: keepOffline);

  List<Article> favorites() => _db.favorites();

  bool isFavorite(String id) => _db.isFavorite(id);
  Future<void> toggleFavorite(Article a) => _db.toggleFavorite(a);

  bool isRead(String id) => _db.isRead(id);
  Future<void> markRead(String id) => _db.markRead(id);

  void dispose() => _service.dispose();
}
