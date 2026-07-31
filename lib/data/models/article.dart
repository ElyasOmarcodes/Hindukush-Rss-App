/// A single news item / post parsed from a WordPress RSS feed.
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
    this.categories = const [],
    this.categoryId = 'home',
    this.lang = '',
    int? cachedAtMs,
  }) : cachedAtMs = cachedAtMs ?? DateTime.now().millisecondsSinceEpoch;

  /// Stable identity — the feed guid, or the link as a fallback.
  final String id;
  final String title;
  final String link;
  final String? author;
  final DateTime? published;

  /// Short plain-text excerpt (one line in lists).
  final String summary;

  /// Full HTML body from `content:encoded` (rendered in the post view).
  final String contentHtml;
  final String? imageUrl;
  final List<String> categories;

  /// Id of the [FeedCategory] this article was fetched under.
  final String categoryId;

  /// Language code of the site this article came from ('ps' / 'fa' / 'en').
  /// Everything read back out of the cache is filtered on this, so content
  /// from one language can never appear while another language is selected.
  final String lang;

  final int cachedAtMs;

  DateTime get cachedAt => DateTime.fromMillisecondsSinceEpoch(cachedAtMs);

  /// The key this article is stored under. Composite, so two sites can never
  /// collide even if they ever served the same post id.
  String get storageKey => '$lang|$id';

  static String keyFor(String lang, String id) => '$lang|$id';

  Article copyWith({String? categoryId, String? lang, int? cachedAtMs}) =>
      Article(
        id: id,
        title: title,
        link: link,
        author: author,
        published: published,
        summary: summary,
        contentHtml: contentHtml,
        imageUrl: imageUrl,
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
