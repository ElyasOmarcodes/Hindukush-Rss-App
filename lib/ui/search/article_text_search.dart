import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/config/feeds.dart';
import '../../core/localization/strings.dart';

/// Full-text search **inside a single article** (the one currently open in the
/// post view), rather than across the feed. Every occurrence is listed with the
/// surrounding sentence and the matched word highlighted.
class ArticleTextSearchDelegate extends SearchDelegate<void> {
  ArticleTextSearchDelegate({
    required this.lang,
    required String title,
    required String html,
  })  : _text = '${title.trim()}\n\n${htmlToPlainText(html)}',
        super(searchFieldLabel: S.of(lang).searchInArticle);

  final AppLanguage lang;
  final String _text;

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: Icon(lang.isRtl ? Icons.arrow_forward : Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    final s = S.of(lang);
    final scheme = Theme.of(context).colorScheme;
    final needle = query.trim();

    if (needle.isEmpty) {
      return _hint(context, Icons.find_in_page_outlined, s.searchInArticle);
    }

    final hits = _find(needle);
    if (hits.isEmpty) {
      return _hint(context, Icons.search_off_rounded, s.noMatches);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: hits.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 16, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  s.matchesN(hits.length),
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }
        return _HitCard(hit: hits[i - 1], index: i, scheme: scheme);
      },
    );
  }

  /// Every case-insensitive occurrence of [needle], with surrounding context.
  List<_Hit> _find(String needle) {
    final haystack = _text.toLowerCase();
    final q = needle.toLowerCase();
    final hits = <_Hit>[];
    var i = haystack.indexOf(q);
    while (i != -1 && hits.length < 300) {
      final start = math.max(0, i - 70);
      final end = math.min(_text.length, i + q.length + 90);
      hits.add(_Hit(
        before: _text.substring(start, i).replaceAll('\n', ' '),
        match: _text.substring(i, i + q.length),
        after: _text.substring(i + q.length, end).replaceAll('\n', ' '),
        clippedStart: start > 0,
        clippedEnd: end < _text.length,
      ));
      i = haystack.indexOf(q, i + q.length);
    }
    return hits;
  }

  Widget _hint(BuildContext context, IconData icon, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _Hit {
  const _Hit({
    required this.before,
    required this.match,
    required this.after,
    required this.clippedStart,
    required this.clippedEnd,
  });

  final String before;
  final String match;
  final String after;
  final bool clippedStart;
  final bool clippedEnd;
}

class _HitCard extends StatelessWidget {
  const _HitCard({
    required this.hit,
    required this.index,
    required this.scheme,
  });

  final _Hit hit;
  final int index;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.5,
        );
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: body,
                children: [
                  if (hit.clippedStart) const TextSpan(text: '… '),
                  TextSpan(text: hit.before),
                  TextSpan(
                    text: hit.match,
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      backgroundColor: scheme.primaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(text: hit.after),
                  if (hit.clippedEnd) const TextSpan(text: ' …'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Turns WordPress `content:encoded` HTML into readable plain text so it can be
/// searched (and so the snippets don't contain markup).
String htmlToPlainText(String html) {
  var t = html;
  t = t.replaceAll(
      RegExp(r'<script[^>]*>.*?</script>', dotAll: true, caseSensitive: false),
      ' ');
  t = t.replaceAll(
      RegExp(r'<style[^>]*>.*?</style>', dotAll: true, caseSensitive: false),
      ' ');
  t = t.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  t = t.replaceAll(
      RegExp(r'</(p|div|h[1-6]|li|tr)>', caseSensitive: false), '\n');
  t = t.replaceAll(RegExp(r'<[^>]+>'), ' ');

  // Numeric entities, then the handful of named ones that actually show up.
  t = t.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
    final code = int.tryParse(m[1]!);
    return code == null ? m[0]! : String.fromCharCode(code);
  });
  const named = {
    '&nbsp;': ' ',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&apos;': "'",
    '&hellip;': '…',
    '&mdash;': '—',
    '&ndash;': '–',
    '&laquo;': '«',
    '&raquo;': '»',
    '&rsquo;': '’',
    '&lsquo;': '‘',
    '&ldquo;': '“',
    '&rdquo;': '”',
  };
  named.forEach((k, v) => t = t.replaceAll(k, v));

  t = t.replaceAll(RegExp(r'[ \t ]+'), ' ');
  t = t.replaceAll(RegExp(r'\s*\n\s*'), '\n');
  t = t.replaceAll(RegExp(r'\n{2,}'), '\n\n');
  return t.trim();
}
