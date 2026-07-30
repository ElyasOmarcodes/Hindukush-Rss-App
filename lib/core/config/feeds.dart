// ---------------------------------------------------------------------------
// Central feed configuration for Hindukush Ghag.
//
// The three sites are WordPress installations, so every feed follows the
// standard WordPress conventions:
//
//   * Main (home) feed      ->  {baseUrl}/feed/
//   * A category feed       ->  {baseUrl}/category/{slug}/feed/
//
// Only two category slugs could be verified from outside the network
// (`world` and `article`); the rest are the conventional English slugs that
// WordPress normally generates. If a section ever comes back empty, open the
// section page in a browser (e.g. https://hindukushpa.com/category/world/),
// copy the real slug out of the URL, and correct it *here only* — the whole
// app reads its menu from this one file.
// ---------------------------------------------------------------------------

/// The three languages / sites the app can switch between.
enum AppLanguage { pashto, dari, english }

extension AppLanguageX on AppLanguage {
  /// ISO code used for locale + persistence.
  String get code => switch (this) {
        AppLanguage.pashto => 'ps',
        AppLanguage.dari => 'fa',
        AppLanguage.english => 'en',
      };

  /// The WordPress site this language reads from.
  String get baseUrl => switch (this) {
        AppLanguage.pashto => 'https://hindukushpa.com',
        AppLanguage.dari => 'https://hindokosh.com',
        AppLanguage.english => 'https://hindukushen.com',
      };

  bool get isRtl => this != AppLanguage.english;

  /// Native name of the language (shown in the language picker).
  String get nativeName => switch (this) {
        AppLanguage.pashto => 'پښتو',
        AppLanguage.dari => 'دری',
        AppLanguage.english => 'English',
      };

  static AppLanguage fromCode(String? code) => switch (code) {
        'fa' => AppLanguage.dari,
        'en' => AppLanguage.english,
        _ => AppLanguage.pashto,
      };
}

/// A single entry in the app's content menu. When [slug] is `null` the entry
/// points at the site's main feed (`/feed/`); otherwise at the category feed.
class FeedCategory {
  const FeedCategory({
    required this.id,
    required this.slug,
    required this.labels,
    this.children = const [],
  });

  final String id;
  final String? slug;
  final Map<AppLanguage, String> labels;
  final List<FeedCategory> children;

  String label(AppLanguage lang) => labels[lang] ?? labels[AppLanguage.english] ?? id;

  bool get hasChildren => children.isNotEmpty;

  /// The resolved RSS URL for a given language/site.
  String feedUrl(AppLanguage lang) {
    final base = lang.baseUrl;
    if (slug == null) return '$base/feed/';
    return '$base/category/$slug/feed/';
  }

  /// Flattens this category and all descendants into a single list.
  List<FeedCategory> flattened() =>
      [this, for (final c in children) ...c.flattened()];
}

Map<AppLanguage, String> _l(String ps, String fa, String en) => {
      AppLanguage.pashto: ps,
      AppLanguage.dari: fa,
      AppLanguage.english: en,
    };

/// The home / main feed (all latest content across the site).
const FeedCategory kHomeFeed = FeedCategory(
  id: 'home',
  slug: null,
  labels: {
    AppLanguage.pashto: 'کورپاڼه',
    AppLanguage.dari: 'خانه',
    AppLanguage.english: 'Home',
  },
);

/// The full section tree, exactly matching the site's navigation menu.
final List<FeedCategory> kSections = [
  FeedCategory(
    id: 'news',
    slug: 'news',
    labels: _l('خبرونه', 'خبرها', 'News'),
    children: [
      FeedCategory(id: 'news-picks', slug: 'news-picks', labels: _l('خبري غورچاڼ', 'گزیده خبرها', 'News Picks')),
      FeedCategory(id: 'afghanistan', slug: 'afghanistan', labels: _l('افغانستان', 'افغانستان', 'Afghanistan')),
      FeedCategory(id: 'region', slug: 'region', labels: _l('سیمه', 'منطقه', 'Region')),
      FeedCategory(id: 'middle-east', slug: 'middle-east', labels: _l('منځنی ختیځ', 'خاورمیانه', 'Middle East')),
      FeedCategory(id: 'world', slug: 'world', labels: _l('نړۍ', 'جهان', 'World')),
    ],
  ),
  FeedCategory(id: 'comments', slug: 'comment', labels: _l('تبصرې', 'تبصره‌ها', 'Commentary')),
  FeedCategory(
    id: 'articles',
    slug: 'article',
    labels: _l('لیکني', 'مقالات', 'Articles'),
    children: [
      FeedCategory(id: 'religious', slug: 'religious-article', labels: _l('دیني لیکني', 'مقالات دینی', 'Religious Articles')),
      FeedCategory(id: 'important', slug: 'important-article', labels: _l('مهمي لیکني', 'مقالات مهم', 'Important Articles')),
      FeedCategory(id: 'political', slug: 'political-article', labels: _l('سیاسي لیکني', 'مقالات سیاسی', 'Political Articles')),
      FeedCategory(id: 'selected', slug: 'selected-article', labels: _l('انتخاب شوي لیکني', 'مقالات منتخب', 'Selected Articles')),
    ],
  ),
  FeedCategory(id: 'world-media', slug: 'world-media', labels: _l('نړیوالي رسنۍ', 'رسانه‌های جهانی', 'World Media')),
  FeedCategory(id: 'raz', slug: 'raz', labels: _l('راز', 'راز', 'Raz')),
  FeedCategory(id: 'tabyin', slug: 'tabyin', labels: _l('تبین', 'تبیین', 'Tabyin')),
  FeedCategory(id: 'dark-faces', slug: 'dark-faces', labels: _l('تورې څېرې', 'چهره‌های سیاه', 'Dark Faces')),
  FeedCategory(id: 'videos', slug: 'video', labels: _l('ویډیوګانې', 'ویدیوها', 'Videos')),
];

/// A flat list of every selectable category (sections + subcategories).
final List<FeedCategory> kAllCategories = [
  for (final s in kSections) ...s.flattened(),
];

/// Looks a category up by its stable id (used when restoring navigation state).
FeedCategory? categoryById(String id) {
  if (id == kHomeFeed.id) return kHomeFeed;
  for (final c in kAllCategories) {
    if (c.id == id) return c;
  }
  return null;
}
