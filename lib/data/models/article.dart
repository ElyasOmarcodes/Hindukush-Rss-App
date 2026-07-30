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
  final int cachedAtMs;

  DateTime get cachedAt => DateTime.fromMillisecondsSinceEpoch(cachedAtMs);

  Article copyWith({String? categoryId, int? cachedAtMs}) => Article(
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
        cachedAtMs: (map['cachedAtMs'] as int?) ??
            DateTime.now().millisecondsSinceEpoch,
      );

  @override
  bool operator ==(Object other) => other is Article && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
