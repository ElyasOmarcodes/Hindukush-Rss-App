import 'dart:async';

import 'package:http/http.dart' as http;

import '../models/article.dart';
import 'rss_parser.dart';

/// Fetches and parses a remote RSS feed.
class RssService {
  RssService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _headers = {
    'User-Agent': 'HindukushGhag/1.0 (+https://hindukushpa.com; Flutter app)',
    'Accept': 'application/rss+xml, application/xml, text/xml, */*',
  };

  Future<List<Article>> fetch(String url, {String categoryId = 'home'}) async {
    final resp = await _get(url);
    final body = resp.body;
    if (!body.contains('<rss') && !body.contains('<feed')) {
      throw RssException('Response is not a feed: $url');
    }
    return RssParser.parse(body, categoryId: categoryId);
  }

  /// Same resilience as the REST client: three tries, growing timeout, short
  /// backoff — so a momentary drop on a weak signal doesn't fail the load.
  Future<http.Response> _get(String url) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
      try {
        final resp = await _client
            .get(Uri.parse(url), headers: _headers)
            .timeout(Duration(seconds: 15 + attempt * 10));
        if (resp.statusCode == 200) return resp;
        if (resp.statusCode >= 400 && resp.statusCode < 500) {
          throw RssException('HTTP ${resp.statusCode} for $url');
        }
        lastError = RssException('HTTP ${resp.statusCode} for $url');
      } on RssException {
        rethrow;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? RssException('Request failed: $url');
  }

  void dispose() => _client.close();
}

class RssException implements Exception {
  RssException(this.message);
  final String message;
  @override
  String toString() => 'RssException: $message';
}
