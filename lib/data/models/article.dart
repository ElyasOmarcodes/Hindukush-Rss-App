import '../../core/util/html_text.dart';

/// A single news item / post.
class Article {
  Article({
    required this.id,
    required this.title,
    required this.link,
    this.author,
    this.published,
    this.summary = '',
    this.contentHtml = '',
    this.imageUrl,
    this.thumbUrl,
    this.wpId,
    int? readMinutes,
    this.categories = const [],
    this.categoryId = 'home',
    this.lang = '',
    int? cachedAtMs,
  })  : readMinutes = readMinutes ?? estimateReadMinutes(contentHtml),
        cachedAtMs = cachedAtMs ?? DateTime.now().millisecondsSinceEpoch;

  /// Stable identity — the post's URL (unique across the three sites).
  final String id;
  final String title;
  final String link;
  final String? author;
  final DateTime? published;

  /// Short plain-text excerpt.
  final String summary;

  /// Full HTML body. Lists are fetched *without* it (it is by far the largest
  /// part of the response); it's filled in when the post is opened, or by the
  /// background prefetch.
  final String contentHtml;

  /// Large image for the carousel and the post header.
  final String? imageUrl;

  /// Small image for list rows. A 96px thumbnail doesn't need a 768px photo —
  /// on a weak connection that difference is most of the page's weight.
  final String? thumbUrl;

  /// WordPress post id, used to fetch the full body on demand. Null for posts
  /// that came from the RSS fallback (those already carry their body).
  final int? wpId;

  /// Estimated reading time; null until the body is known.
  final int? readMinutes;

  final List<String> categories;

  /// Id of the [FeedCategory] this article was fetched under.
  final String categoryId;

  /// Language code of the site this article came from ('ps' / 'fa' / 'en').
  /// Everything read back out of the cache is filtered on this, so content
  /// from one language can never appear while another language is selected.
  final String lang;

  final int cachedAtMs;

  DateTime get cachedAt => DateTime.fromMillisecondsSinceEpoch(cachedAtMs);

  bool get hasContent => contentHtml.trim().isNotEmpty;

  /// Best image for a list row.
  String? get listImage => thumbUrl ?? imageUrl;

  /// The key this article is stored under. Composite, so two sites can never
  /// collide even if they ever served the same post id.
  String get storageKey => '$lang|$id';

  static String keyFor(String lang, String id) => '$lang|$id';

  /// ~200 words a minute, never less than one minute.
  static int? estimateReadMinutes(String html) {
    if (html.trim().isEmpty) return null;
    final words = htmlToPlainText(html)
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    if (words == 0) return null;
    final minutes = (words / 200).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  Article copyWith({
    String? categoryId,
    String? lang,
    int? cachedAtMs,
    String? contentHtml,
    String? author,
    String? imageUrl,
    String? thumbUrl,
    int? readMinutes,
  }) =>
      Article(
        id: id,
        title: title,
        link: link,
        author: author ?? this.author,
        published: published,
        summary: summary,
        contentHtml: contentHtml ?? this.contentHtml,
        imageUrl: imageUrl ?? this.imageUrl,
        thumbUrl: thumbUrl ?? this.thumbUrl,
        wpId: wpId,
        readMinutes: contentHtml != null ? null : (readMinutes ?? this.readMinutes),
        categories: categories,
        categoryId: categoryId ?? this.categoryId,
        lang: lang ?? this.lang,
        cachedAtMs: cachedAtMs ?? this.cachedAtMs,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'link': link,
        'author': author,
        'published': published?.millisecondsSinceEpoch,
        'summary': summary,
        'contentHtml': contentHtml,
        'imageUrl': imageUrl,
        'thumbUrl': thumbUrl,
        'wpId': wpId,
        'readMinutes': readMinutes,
        'categories': categories,
        'categoryId': categoryId,
        'lang': lang,
        'cachedAtMs': cachedAtMs,
      };

  static Article fromMap(Map map) => Article(
        id: map['id'] as String,
        title: (map['title'] as String?) ?? '',
        link: (map['link'] as String?) ?? '',
        author: map['author'] as String?,
        published: map['published'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['published'] as int),
        summary: (map['summary'] as String?) ?? '',
        contentHtml: (map['contentHtml'] as String?) ?? '',
        imageUrl: map['imageUrl'] as String?,
        thumbUrl: map['thumbUrl'] as String?,
        wpId: map['wpId'] as int?,
        readMinutes: map['readMinutes'] as int?,
        categories: (map['categories'] as List?)?.cast<String>() ?? const [],
        categoryId: (map['categoryId'] as String?) ?? 'home',
        lang: (map['lang'] as String?) ?? '',
        cachedAtMs: (map['cachedAtMs'] as int?) ??
            DateTime.now().millisecondsSinceEpoch,
      );

  @override
  bool operator ==(Object other) =>
      other is Article && other.id == id && other.lang == lang;

  @override
  int get hashCode => Object.hash(id, lang);
}
