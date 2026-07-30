import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/feeds.dart';
import '../models/article.dart';

/// Reads content from the WordPress REST API. Unlike the RSS feeds, the REST
/// API reliably exposes each post's *featured image* (via `_embed` →
/// `wp:featuredmedia`), which fixes the "missing images" problem.
class WpService {
  WpService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Cache of slug -> category id, per site base url.
  final Map<String, Map<String, int>> _catCache = {};

  static const _headers = {
    'User-Agent': 'HindukushGhag/1.0 (Flutter app)',
    'Accept': 'application/json',
  };

  Future<List<Article>> fetchLatest(AppLanguage lang,
      {int perPage = 20, String categoryId = 'home'}) async {
    final url =
        '${lang.baseUrl}/wp-json/wp/v2/posts?_embed=1&per_page=$perPage';
    return _fetchPosts(url, categoryId);
  }

  Future<List<Article>> fetchCategory(
      FeedCategory category, AppLanguage lang,
      {int perPage = 20}) async {
    final slug = category.slug(lang);
    if (slug == null) {
      throw WpException('No slug for ${category.id} in ${lang.code}');
    }
    final id = await _resolveCategoryId(lang, slug);
    if (id == null) {
      throw WpException('Category "$slug" not found on ${lang.baseUrl}');
    }
    final url = '${lang.baseUrl}/wp-json/wp/v2/posts'
        '?_embed=1&per_page=$perPage&categories=$id';
    return _fetchPosts(url, category.id);
  }

  // --- internals -----------------------------------------------------------

  Future<List<Article>> _fetchPosts(String url, String categoryId) async {
    final resp = await _client
        .get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (resp.statusCode != 200) {
      throw WpException('HTTP ${resp.statusCode} for $url');
    }
    final data = jsonDecode(utf8.decode(resp.bodyBytes));
    if (data is! List) throw WpException('Unexpected REST response');
    return [
      for (final p in data)
        if (p is Map) _mapPost(p, categoryId),
    ];
  }

  Future<int?> _resolveCategoryId(AppLanguage lang, String slug) async {
    final base = lang.baseUrl;
    final map = _catCache[base] ??= await _loadCategories(base);
    final key = _norm(slug);
    return map[key];
  }

  Future<Map<String, int>> _loadCategories(String base) async {
    final out = <String, int>{};
    for (var page = 1; page <= 10; page++) {
      final url = '$base/wp-json/wp/v2/categories'
          '?per_page=100&page=$page&_fields=id,slug';
      try {
        final resp = await _client
            .get(Uri.parse(url), headers: _headers)
            .timeout(const Duration(seconds: 20));
        if (resp.statusCode != 200) break;
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
    final embedded = post['_embedded'];

    String? image;
    List<String> categories = const [];
    String? author;
    if (embedded is Map) {
      // featured image
      final media = embedded['wp:featuredmedia'];
      if (media is List && media.isNotEmpty && media.first is Map) {
        image = _bestImage(media.first as Map);
      }
      // author
      final authors = embedded['author'];
      if (authors is List && authors.isNotEmpty && authors.first is Map) {
        author = (authors.first as Map)['name']?.toString();
      }
      // category / tag terms
      final terms = embedded['wp:term'];
      if (terms is List) {
        categories = [
          for (final group in terms)
            if (group is List)
              for (final t in group)
                if (t is Map && t['name'] != null) t['name'].toString(),
        ];
      }
    }

    final link = post['link']?.toString() ?? '';
    final id = link.isNotEmpty ? link : (post['id']?.toString() ?? link);
    final title = _decode(_rendered(post['title']));
    final content = _rendered(post['content']);
    final excerpt = _stripHtml(_rendered(post['excerpt']));

    // Prefer an <img> from the body if the REST featured image is absent.
    image ??= _firstBodyImage(content);

    return Article(
      id: id,
      title: title,
      link: link,
      author: (author != null && author.trim().isNotEmpty) ? author : null,
      published: _parseDate(post),
      summary: excerpt,
      contentHtml: content,
      imageUrl: image,
      categories: categories,
      categoryId: categoryId,
    );
  }

  String _rendered(dynamic node) {
    if (node is Map && node['rendered'] != null) {
      return node['rendered'].toString();
    }
    return node?.toString() ?? '';
  }

  String? _bestImage(Map media) {
    final details = media['media_details'];
    if (details is Map && details['sizes'] is Map) {
      final sizes = details['sizes'] as Map;
      for (final name in ['medium_large', 'large', 'medium', 'full']) {
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
