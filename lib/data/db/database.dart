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
    await _purgeUnattributed();
    _ready = true;
  }

  /// Drops rows written before articles carried a language (and any row that
  /// somehow lost its language), so they can't linger invisibly on disk.
  Future<void> _purgeUnattributed() async {
    final stale = <dynamic>[
      for (final key in _articles.keys)
        if (_articles.get(key) is! Map ||
            ((_articles.get(key) as Map)['lang'] as String? ?? '').isEmpty)
          key,
    ];
    for (final key in stale) {
      await _articles.delete(key);
    }
  }

  // --- caching -------------------------------------------------------------

  /// Upserts fetched articles, preserving the earliest cache timestamp so the
  /// auto-delete window is measured from when we first saw an item.
  ///
  /// Rows are keyed `lang|id`, so the three sites occupy disjoint key spaces.
  Future<void> cacheArticles(List<Article> articles) async {
    for (final a in articles) {
      if (a.lang.isEmpty) continue; // never store unattributed rows
      final existing = _articles.get(a.storageKey);
      final cachedAtMs = existing is Map
          ? (existing['cachedAtMs'] as int? ?? a.cachedAtMs)
          : a.cachedAtMs;
      await _articles.put(
        a.storageKey,
        a.copyWith(cachedAtMs: cachedAtMs).toMap(),
      );
    }
  }

  /// Every cached read is filtered by [lang] as well as the stored key, so a
  /// row written under one language can never surface under another.
  List<Article> cachedByCategory(String categoryId, String lang) {
    final list = _readAll(lang).where((a) => a.categoryId == categoryId).toList();
    _sortByDate(list);
    return list;
  }

  List<Article> allCached(String lang) {
    final list = _readAll(lang).toList();
    _sortByDate(list);
    return list;
  }

  Iterable<Article> _readAll(String lang) => _articles.values
      .whereType<Map>()
      .map(Article.fromMap)
      .where((a) => a.lang == lang);

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

  // Article ids are the post's full URL, so they're already unique across the
  // three sites; the hidden/read sets can stay keyed by id alone.
  bool isHidden(String id) => _hidden.containsKey(id);

  Future<void> hide(String lang, String id) async {
    await _hidden.put(id, true);
    await _articles.delete(Article.keyFor(lang, id));
  }

  // --- read tracking -------------------------------------------------------

  bool isRead(String id) => _reads.containsKey(id);

  Future<void> markRead(String id) async {
    if (!_reads.containsKey(id)) {
      await _reads.put(id, DateTime.now().millisecondsSinceEpoch);
    }
  }

  // --- favorites -----------------------------------------------------------

  bool isFavorite(Article a) => _favorites.containsKey(a.storageKey);

  Future<void> toggleFavorite(Article a) async {
    if (_favorites.containsKey(a.storageKey)) {
      await _favorites.delete(a.storageKey);
    } else {
      await _favorites.put(a.storageKey, a.toMap());
    }
  }

  /// Favorites are language-scoped too, so the tab never mixes sites. Nothing
  /// is deleted — switching back to the other language shows them again.
  List<Article> favorites(String lang) {
    final list = _favorites.values
        .whereType<Map>()
        .map(Article.fromMap)
        .where((a) => a.lang == lang)
        .toList();
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

      // Article rows are keyed `lang|id` while reads are keyed by id alone.
      final id = raw['id'] as String? ?? '';
      final isRead = _reads.containsKey(id);
      final limit = isRead && readMaxDays > 0
          ? (newsMaxDays > 0 ? (readMaxDays < newsMaxDays ? readMaxDays : newsMaxDays) : readMaxDays)
          : newsMaxDays;

      if (limit > 0 && ageDays >= limit) toDelete.add(key);
    }
    for (final key in toDelete) {
      final raw = _articles.get(key);
      if (raw is Map) await _reads.delete(raw['id']);
      await _articles.delete(key);
    }
    return toDelete.length;
  }
}
