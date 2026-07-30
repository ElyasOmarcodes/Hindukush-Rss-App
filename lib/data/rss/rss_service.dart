import 'dart:async';

import 'package:http/http.dart' as http;

import '../models/article.dart';
import 'rss_parser.dart';

/// Fetches and parses a remote RSS feed.
class RssService {
  RssService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Article>> fetch(String url, {String categoryId = 'home'}) async {
    final resp = await _client.get(
      Uri.parse(url),
      headers: const {
        'User-Agent':
            'HindukushGhag/1.0 (+https://hindukushpa.com; Flutter app)',
        'Accept': 'application/rss+xml, application/xml, text/xml, */*',
      },
    ).timeout(const Duration(seconds: 20));

    if (resp.statusCode != 200) {
      throw RssException('HTTP ${resp.statusCode} for $url');
    }
    final body = resp.body;
    if (!body.contains('<rss') && !body.contains('<feed')) {
      throw RssException('Response is not a feed: $url');
    }
    return RssParser.parse(body, categoryId: categoryId);
  }

  void dispose() => _client.close();
}

class RssException implements Exception {
  RssException(this.message);
  final String message;
  @override
  String toString() => 'RssException: $message';
}
