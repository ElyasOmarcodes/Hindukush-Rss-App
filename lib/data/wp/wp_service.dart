import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/feeds.dart';
import '../db/database.dart';
import '../models/article.dart';
import '../net/net.dart';

/// Reads content from the WordPress REST API.
///
/// Weak-network design:
///  * **List requests are light.** They leave out the article body (by far the
///    largest field) and embed only the featured image, not authors and terms.
///  * **The body is fetched on demand** with [fetchContent] when a post is
///    opened (and prefetched for the top few in the background).
///  * **Resolved category ids are remembered on disk**, so opening a section
///    doesn't cost an extra round-trip every launch.
class WpService {
  WpService({http.Client? client, NewsDatabase? db})
      : _client = client ?? Net.createClient(),
        _db = db;

  final http.Client _client;
  final NewsDatabase? _db;

  /// Cache of slug -> category id, per site base url.
  final Map<String, Map<String, int>> _catCache = {};

  static const _headers = {
    'User-Agent': 'HindukushGhag/1.0 (Flutter app)',
    'Accept': 'application/json',
  };

  /// Everything a list row needs — and nothing else. No `content`.
  static const _listFields =
      'id,link,title,excerpt,date,date_gmt,jetpack_featured_media_url,'
      '_links,_embedded';

  /// Twelve rows fill more than a screen; fewer rows = a faster first paint.
  static const _perPage = 12;

  Future<List<Article>> fetchLatest(AppLanguage lang,
      {String categoryId = 'home'}) async {
    final url = '${lang.baseUrl}/wp-json/wp/v2/posts'
        '?_embed=wp:featuredmedia&per_page=$_perPage&_fields=$_listFields';
    return _fetchPosts(url, categoryId);
  }

  Future<List<Article>> fetchCategory(
      FeedCategory category, AppLanguage lang) async {
    final slug = category.slug(lang);
    if (slug == null) {
      throw WpException('No slug for ${category.id} in ${lang.code}');
    }
    final id = await _resolveCategoryId(lang, slug);
    if (id == null) {
      throw WpException('Category "$slug" not found on ${lang.baseUrl}');
    }
    final url = '${lang.baseUrl}/wp-json/wp/v2/posts'
        '?_embed=wp:featuredmedia&per_page=$_perPage&categories=$id'
        '&_fields=$_listFields';
    return _fetchPosts(url, category.id);
  }

  /// The full body (and author) of one post.
  Future<({String content, String? author})> fetchContent(
      AppLanguage lang, int wpId) async {
    final url = '${lang.baseUrl}/wp-json/wp/v2/posts/$wpId'
        '?_embed=author&_fields=id,content,_links,_embedded';
    final resp = await _get(url);
    final data = jsonDecode(utf8.decode(resp.bodyBytes));
    if (data is! Map) throw WpException('Unexpected REST response');
    String? author;
    final embedded = data['_embedded'];
    if (embedded is Map) {
      final authors = embedded['author'];
      if (authors is List && authors.isNotEmpty && authors.first is Map) {
        author = (authors.first as Map)['name']?.toString();
      }
    }
    return (
      content: _rendered(data['content']),
      author: (author != null && author.trim().isNotEmpty) ? author : null,
    );
  }

  // --- internals -----------------------------------------------------------

  Future<List<Article>> _fetchPosts(String url, String categoryId) async {
    final resp = await _get(url);
    final data = jsonDecode(utf8.decode(resp.bodyBytes));
    if (data is! List) throw WpException('Unexpected REST response');
    return [
      for (final p in data)
        if (p is Map) _mapPost(p, categoryId),
    ];
  }

  Future<http.Response> _get(String url) =>
      Net.get(_client, url, headers: _headers);

  Future<int?> _resolveCategoryId(AppLanguage lang, String slug) async {
    final base = lang.baseUrl;
    final map = _catCache[base] ??= <String, int>{};
    final key = _norm(slug);
    if (map.containsKey(key)) return map[key];

    // Resolved on an earlier launch?
    final metaKey = 'cat|$base|$key';
    final stored = _db?.meta(metaKey);
    if (stored is int) return map[key] = stored;

    // Ask for exactly this slug (one small request) instead of paging through
    // every category on the site before a single post can load.
    try {
      final resp = await _get('$base/wp-json/wp/v2/categories'
          '?slug=${Uri.encodeQueryComponent(slug)}&_fields=id,slug&per_page=5');
      final data = jsonDecode(utf8.decode(resp.bodyBytes));
      if (data is List) {
        for (final c in data) {
          if (c is Map && c['slug'] != null && c['id'] is int) {
            map[_norm(c['slug'].toString())] = c['id'] as int;
          }
        }
      }
    } catch (_) {
      // fall through to the slower lookup below
    }
    if (map.containsKey(key)) {
      await _db?.putMeta(metaKey, map[key]);
      return map[key];
    }

    // Some sites percent-encode non-Latin slugs differently than we do, so as
    // a last resort fall back to listing the categories once.
    if (!_listed.contains(base)) {
      _listed.add(base);
      map.addAll(await _loadCategories(base));
    }
    if (map[key] != null) await _db?.putMeta(metaKey, map[key]);
    return map[key];
  }

  /// Sites whose full category list has already been pulled once.
  final Set<String> _listed = {};

  Future<Map<String, int>> _loadCategories(String base) async {
    final out = <String, int>{};
    for (var page = 1; page <= 5; page++) {
      final url = '$base/wp-json/wp/v2/categories'
          '?per_page=100&page=$page&_fields=id,slug';
      try {
        final resp = await _get(url);
        final data = jsonDecode(utf8.decode(resp.bodyBytes));
        if (data is! List || data.isEmpty) break;
        for (final c in data) {
          if (c is Map && c['slug'] != null && c['id'] is int) {
            out[_norm(c['slug'].toString())] = c['id'] as int;
          }
        }
        if (data.length < 100) break;
      } catch (_) {
        break;
      }
    }
    return out;
  }

  /// Normalise a slug for matching: percent-decode + lowercase.
  static String _norm(String slug) {
    var s = slug;
    try {
      s = Uri.decodeComponent(slug);
    } catch (_) {}
    return s.toLowerCase();
  }

  Article _mapPost(Map post, String categoryId) {
    String? image;
    String? thumb;
    final embedded = post['_embedded'];
    if (embedded is Map) {
      final media = embedded['wp:featuredmedia'];
      if (media is List && media.isNotEmpty && media.first is Map) {
        final m = media.first as Map;
        image = _pickSize(m, const ['medium_large', 'large', 'medium', 'full']);
        thumb = _pickSize(m, const ['medium', 'thumbnail', 'medium_large']);
      }
    }
    // Some sites expose the featured image directly (Jetpack).
    final jetpack = post['jetpack_featured_media_url']?.toString();
    if (image == null && jetpack != null && jetpack.isNotEmpty) image = jetpack;

    final content = _rendered(post['content']);
    // Only possible if the body was requested; harmless otherwise.
    image ??= content.isEmpty ? null : _firstBodyImage(content);

    final link = post['link']?.toString() ?? '';
    final id = link.isNotEmpty ? link : (post['id']?.toString() ?? link);

    return Article(
      id: id,
      title: _decode(_rendered(post['title'])),
      link: link,
      published: _parseDate(post),
      summary: _stripHtml(_rendered(post['excerpt'])),
      contentHtml: content,
      imageUrl: image,
      thumbUrl: thumb,
      wpId: post['id'] is int ? post['id'] as int : null,
      categoryId: categoryId,
    );
  }

  String _rendered(dynamic node) {
    if (node is Map && node['rendered'] != null) {
      return node['rendered'].toString();
    }
    return node?.toString() ?? '';
  }

  /// The first available rendition from [preferred], else the original.
  String? _pickSize(Map media, List<String> preferred) {
    final details = media['media_details'];
    if (details is Map && details['sizes'] is Map) {
      final sizes = details['sizes'] as Map;
      for (final name in preferred) {
        final s = sizes[name];
        if (s is Map && s['source_url'] != null) {
          return s['source_url'].toString();
        }
      }
    }
    return media['source_url']?.toString();
  }

  String? _firstBodyImage(String html) {
    final m = RegExp(r'<img[^>]+src\s*=\s*["' r"'" r']([^"' r"'" r']+)')
        .firstMatch(html);
    return m?.group(1);
  }

  DateTime? _parseDate(Map post) {
    final raw = post['date_gmt']?.toString() ?? post['date']?.toString();
    if (raw == null || raw.isEmpty) return null;
    try {
      // date_gmt has no zone suffix; treat as UTC.
      final iso = raw.endsWith('Z') || raw.contains('+') ? raw : '${raw}Z';
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }

  static String _stripHtml(String html) {
    final noTags = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
    return _decode(noTags).replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _decode(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&hellip;', '…')
      .replaceAll('&#8230;', '…')
      .replaceAll('&#8217;', '’')
      .replaceAll('&#8216;', '‘')
      .replaceAll(RegExp(r'\[&hellip;\]|\[…\]'), '…')
      .trim();

  void dispose() => _client.close();
}

class WpException implements Exception {
  WpException(this.message);
  final String message;
  @override
  String toString() => 'WpException: $message';
}
