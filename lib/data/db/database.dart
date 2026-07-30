import 'package:hive_flutter/hive_flutter.dart';

import '../models/article.dart';

/// Pure-Dart offline store (Hive) — no native SQLite dependency, so it builds
/// cleanly for Android, iOS *and* the Windows desktop target.
///
/// Three boxes:
///   * `articles`  — the rolling news cache (subject to auto-delete rules)
///   * `reads`     — id -> timestamp when the article was opened
///   * `favorites` — full article snapshots the user chose to keep forever
class NewsDatabase {
  NewsDatabase._();
  static final NewsDatabase instance = NewsDatabase._();

  static const _articlesBox = 'articles';
  static const _readsBox = 'reads';
  static const _favoritesBox = 'favorites';
  static const _hiddenBox = 'hidden';

  late Box _articles;
  late Box _reads;
  late Box _favorites;
  late Box _hidden;

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    await Hive.initFlutter();
    _articles = await Hive.openBox(_articlesBox);
    _reads = await Hive.openBox(_readsBox);
    _favorites = await Hive.openBox(_favoritesBox);
    _hidden = await Hive.openBox(_hiddenBox);
    _ready = true;
  }

  // --- caching -------------------------------------------------------------

  /// Upserts fetched articles, preserving the earliest cache timestamp so the
  /// auto-delete window is measured from when we first saw an item.
  Future<void> cacheArticles(List<Article> articles) async {
    for (final a in articles) {
      final existing = _articles.get(a.id);
      final cachedAtMs = existing is Map
          ? (existing['cachedAtMs'] as int? ?? a.cachedAtMs)
          : a.cachedAtMs;
      await _articles.put(a.id, a.copyWith(cachedAtMs: cachedAtMs).toMap());
    }
  }

  List<Article> cachedByCategory(String categoryId) {
    final list = _articles.values
        .whereType<Map>()
        .map(Article.fromMap)
        .where((a) => a.categoryId == categoryId)
        .toList();
    _sortByDate(list);
    return list;
  }

  List<Article> allCached() {
    final list =
        _articles.values.whereType<Map>().map(Article.fromMap).toList();
    _sortByDate(list);
    return list;
  }

  int get storedCount => _articles.length;

  /// Newest first: by publish date (nulls last), then by cache time.
  void _sortByDate(List<Article> list) {
    list.sort((a, b) {
      final ad = a.published;
      final bd = b.published;
      if (ad == null && bd == null) {
        return b.cachedAtMs.compareTo(a.cachedAtMs);
      }
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
  }

  Future<void> clearCache() async {
    await _articles.clear();
    await _reads.clear();
  }

  // --- read tracking -------------------------------------------------------

  // --- local delete (hide) ------------------------------------------------

  bool isHidden(String id) => _hidden.containsKey(id);

  Future<void> hide(String id) async {
    await _hidden.put(id, true);
    await _articles.delete(id);
  }

  // --- read tracking -------------------------------------------------------

  bool isRead(String id) => _reads.containsKey(id);

  Future<void> markRead(String id) async {
    if (!_reads.containsKey(id)) {
      await _reads.put(id, DateTime.now().millisecondsSinceEpoch);
    }
  }

  // --- favorites -----------------------------------------------------------

  bool isFavorite(String id) => _favorites.containsKey(id);

  Future<void> toggleFavorite(Article a) async {
    if (_favorites.containsKey(a.id)) {
      await _favorites.delete(a.id);
    } else {
      await _favorites.put(a.id, a.toMap());
    }
  }

  List<Article> favorites() {
    final list =
        _favorites.values.whereType<Map>().map(Article.fromMap).toList();
    list.sort((a, b) => b.cachedAtMs.compareTo(a.cachedAtMs));
    return list;
  }

  // --- maintenance / auto-delete ------------------------------------------

  /// Applies the retention rules. Favorites are never touched.
  /// [newsMaxDays] / [readMaxDays] == 0 means "never delete".
  Future<int> applyRetention({
    required int newsMaxDays,
    required int readMaxDays,
  }) async {
    final now = DateTime.now();
    final toDelete = <dynamic>[];
    for (final key in _articles.keys) {
      if (_favorites.containsKey(key)) continue;
      final raw = _articles.get(key);
      if (raw is! Map) continue;
      final cachedAtMs =
          raw['cachedAtMs'] as int? ?? now.millisecondsSinceEpoch;
      final ageDays =
          now.difference(DateTime.fromMillisecondsSinceEpoch(cachedAtMs)).inDays;

      final isRead = _reads.containsKey(key);
      final limit = isRead && readMaxDays > 0
          ? (newsMaxDays > 0 ? (readMaxDays < newsMaxDays ? readMaxDays : newsMaxDays) : readMaxDays)
          : newsMaxDays;

      if (limit > 0 && ageDays >= limit) toDelete.add(key);
    }
    for (final key in toDelete) {
      await _articles.delete(key);
      await _reads.delete(key);
    }
    return toDelete.length;
  }
}
