import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

import '../models/article.dart';

/// Parses a WordPress RSS 2.0 document into [Article]s.
///
/// Handles the namespaced tags WordPress emits: `dc:creator`, `content:encoded`,
/// `media:content` / `media:thumbnail`, and `<enclosure>` for the lead image.
class RssParser {
  static List<Article> parse(String xmlString, {String categoryId = 'home'}) {
    final doc = XmlDocument.parse(xmlString);
    final items = doc.findAllElements('item');
    final out = <Article>[];
    for (final item in items) {
      final article = _parseItem(item, categoryId);
      if (article != null) out.add(article);
    }
    return out;
  }

  static Article? _parseItem(XmlElement item, String categoryId) {
    final link = _text(item, 'link');
    String? guid = _text(item, 'guid');
    final id = (guid != null && guid.isNotEmpty) ? guid : link;
    if (id == null || id.isEmpty) return null;

    final title = _unescape(_text(item, 'title') ?? '');
    final creator = _text(item, 'creator') ?? _text(item, 'dc:creator');
    final pubDate = _parseDate(_text(item, 'pubDate'));

    final contentEncoded =
        _text(item, 'encoded') ?? _text(item, 'content:encoded') ?? '';
    final description = _text(item, 'description') ?? '';
    // Prefer the richer content:encoded body; fall back to description.
    final contentHtml =
        contentEncoded.trim().isNotEmpty ? contentEncoded : description;

    final summary = _stripHtml(description.isNotEmpty ? description : contentHtml);

    final categories = item
        .findElements('category')
        .map((e) => _unescape(e.innerText.trim()))
        .where((s) => s.isNotEmpty)
        .toList();

    final imageUrl = _extractImage(item, contentHtml);

    return Article(
      id: id,
      title: title,
      link: link ?? id,
      author: (creator != null && creator.trim().isNotEmpty)
          ? _unescape(creator.trim())
          : null,
      published: pubDate,
      summary: summary,
      contentHtml: contentHtml,
      imageUrl: imageUrl,
      categories: categories,
      categoryId: categoryId,
    );
  }

  // --- helpers -------------------------------------------------------------

  static String? _text(XmlElement parent, String local) {
    for (final el in parent.childElements) {
      if (el.localName == local || el.name.qualified == local) {
        return el.innerText;
      }
    }
    return null;
  }

  static String? _extractImage(XmlElement item, String html) {
    // media:content / media:thumbnail url attribute
    for (final el in item.descendantElements) {
      if (el.localName == 'content' || el.localName == 'thumbnail') {
        final url = el.getAttribute('url');
        if (url != null && _looksLikeImage(url)) return url;
      }
    }
    // <enclosure url="..." type="image/..."/>
    for (final el in item.findElements('enclosure')) {
      final url = el.getAttribute('url');
      final type = el.getAttribute('type') ?? '';
      if (url != null && (type.startsWith('image') || _looksLikeImage(url))) {
        return url;
      }
    }
    // First <img> inside the HTML body.
    final match = RegExp(r'<img[^>]+src\s*=\s*["' r"'" r']([^"' r"'" r']+)')
        .firstMatch(html);
    if (match != null) return match.group(1);
    return null;
  }

  static bool _looksLikeImage(String url) {
    final u = url.toLowerCase();
    return u.endsWith('.jpg') ||
        u.endsWith('.jpeg') ||
        u.endsWith('.png') ||
        u.endsWith('.webp') ||
        u.endsWith('.gif') ||
        u.contains('.jpg?') ||
        u.contains('.png?') ||
        u.contains('.webp?');
  }

  static String _stripHtml(String html) {
    final noTags = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
    return _unescape(noTags).replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _unescape(String s) => s
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
      .replaceAll('&#8216;', '‘');

  static final _rfc822 = DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US');

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final s = raw.trim();
    try {
      // Typical: "Wed, 30 Jul 2025 14:22:05 +0000"
      final cleaned = s.replaceAll(RegExp(r'\s*[+-]\d{4}$|\s*[A-Z]{3,4}$'), '');
      return _rfc822.parseUtc(cleaned);
    } catch (_) {
      try {
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    }
  }
}
