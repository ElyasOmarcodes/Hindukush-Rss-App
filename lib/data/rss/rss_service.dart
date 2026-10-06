import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/article.dart';
import '../net/net.dart';
import 'rss_parser.dart';

/// Fetches and parses a remote RSS feed (the fallback when REST is blocked).
class RssService {
  RssService({http.Client? client}) : _client = client ?? Net.createClient();

  final http.Client _client;

  static const _headers = {
    'User-Agent': 'HindukushGhag/1.0 (+https://hindukushpa.com; Flutter app)',
    'Accept': 'application/rss+xml, application/xml, text/xml, */*',
  };

  Future<List<Article>> fetch(String url, {String categoryId = 'home'}) async {
    final resp = await Net.get(_client, url, headers: _headers);
    final body = utf8.decode(resp.bodyBytes, allowMalformed: true);
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
