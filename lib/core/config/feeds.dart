// ---------------------------------------------------------------------------
// Central feed configuration for Hindukush Ghag.
//
// The three sites are WordPress. Content is read primarily through the
// WordPress REST API (which reliably carries the *featured image* that the RSS
// feeds omit), and falls back to the classic RSS feed if the REST API is
// unavailable:
//
//   REST latest      ->  {baseUrl}/wp-json/wp/v2/posts?_embed&per_page=N
//   REST category    ->  {baseUrl}/wp-json/wp/v2/posts?_embed&categories={id}
//   RSS  main        ->  {baseUrl}/feed/
//   RSS  category    ->  {baseUrl}/category/{slug}/feed/
//
// The slugs below were VERIFIED against each live site (via tool/rss_explorer)
// and differ per language, so every category carries a per-language slug. A
// `null` slug for a language means that section doesn't exist there and is
// hidden for that language.
// ---------------------------------------------------------------------------

/// The three languages / sites the app can switch between.
enum AppLanguage { pashto, dari, english }

extension AppLanguageX on AppLanguage {
  String get code => switch (this) {
        AppLanguage.pashto => 'ps',
        AppLanguage.dari => 'fa',
        AppLanguage.english => 'en',
      };

  String get baseUrl => switch (this) {
        AppLanguage.pashto => 'https://hindukushpa.com',
        AppLanguage.dari => 'https://hindokosh.com',
        AppLanguage.english => 'https://hindukushen.com',
      };

  bool get isRtl => this != AppLanguage.english;

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

/// A single entry in the app's content menu.
class FeedCategory {
  const FeedCategory({
    required this.id,
    required this.labels,
    this.slugs = const {},
    this.children = const [],
  });

  final String id;

  /// Per-language WordPress category slug. `null`/absent => not on that site.
  final Map<AppLanguage, String?> slugs;
  final Map<AppLanguage, String> labels;
  final List<FeedCategory> children;

  String label(AppLanguage lang) =>
      labels[lang] ?? labels[AppLanguage.english] ?? id;

  String? slug(AppLanguage lang) => slugs[lang];

  /// Whether this category exists for [lang]. Home (no slugs map) is always on.
  bool availableFor(AppLanguage lang) =>
      isHome || (slugs.containsKey(lang) && slugs[lang] != null);

  bool get isHome => id == 'home';

  bool get hasChildren => children.isNotEmpty;

  /// RSS fallback URL for [lang].
  String rssUrl(AppLanguage lang) {
    final base = lang.baseUrl;
    final s = slug(lang);
    if (isHome || s == null) return '$base/feed/';
    return '$base/category/$s/feed/';
  }

  List<FeedCategory> flattened() =>
      [this, for (final c in children) ...c.flattened()];
}

Map<AppLanguage, String> _l(String ps, String fa, String en) => {
      AppLanguage.pashto: ps,
      AppLanguage.dari: fa,
      AppLanguage.english: en,
    };

/// Per-language slug map. Pass null where the section is absent on that site.
Map<AppLanguage, String?> _s(String? ps, String? fa, String? en) => {
      AppLanguage.pashto: ps,
      AppLanguage.dari: fa,
      AppLanguage.english: en,
    };

/// The home / latest feed (all newest content across the site).
const FeedCategory kHomeFeed = FeedCategory(
  id: 'home',
  labels: {
    AppLanguage.pashto: 'کورپاڼه',
    AppLanguage.dari: 'خانه',
    AppLanguage.english: 'Home',
  },
);

/// The section tree with VERIFIED per-language slugs.
final List<FeedCategory> kSections = [
  FeedCategory(
    id: 'news',
    labels: _l('خبرونه', 'اخبار', 'News'),
    slugs: _s('خبر', 'اخبار', 'news'),
    children: [
      FeedCategory(
          id: 'news-picks',
          labels: _l('خبري غورچاڼ', 'رویدادهای روز', 'News Bulletin'),
          slugs: _s('news-bulleten', 'news-bulletin', 'news-bulleten')),
      FeedCategory(
          id: 'afghanistan',
          labels: _l('افغانستان', 'افغانستان', 'Afghanistan'),
          slugs: _s('afghanistan', 'afghanistan', 'afghanistan')),
      FeedCategory(
          id: 'region',
          labels: _l('سیمه', 'منطقه', 'Region'),
          slugs: _s('سیمه', 'منطقه', 'region')),
      FeedCategory(
          id: 'middle-east',
          labels: _l('منځنی ختیځ', 'خاورمیانه', 'Middle East'),
          slugs: _s('منځنی-ختیځ', 'خاورمیانه', 'middle-east')),
      FeedCategory(
          id: 'world',
          labels: _l('نړۍ', 'جهان', 'World'),
          slugs: _s('world', 'world', 'world')),
    ],
  ),
  FeedCategory(
    id: 'comments',
    labels: _l('تبصرې', 'تبصره‌ها', 'Commentary'),
    // Only the English site exposes a commentary category feed.
    slugs: _s(null, null, 'commentaries'),
  ),
  FeedCategory(
    id: 'articles',
    labels: _l('لیکني', 'مقالات', 'Articles'),
    slugs: _s('article', 'article', 'articles'),
    children: [
      FeedCategory(
          id: 'religious',
          labels: _l('دیني لیکني', 'مقالات دینی', 'Religious Articles'),
          slugs: _s('dini-likini', 'dini-maqali', 'religious-articles')),
      FeedCategory(
          id: 'important',
          labels: _l('مهمي لیکني', 'مقالات مهم', 'Important Articles'),
          slugs: _s('muhimi-likin', 'important-maqalat', 'important-articles')),
      FeedCategory(
          id: 'political',
          labels: _l('سیاسي لیکني', 'مقالات سیاسی', 'Political Articles'),
          slugs: _s('siasi-likini', 'political-articles', 'political-articles')),
      FeedCategory(
          id: 'selected',
          labels: _l('انتخاب شوي لیکني', 'مقالات منتخب', 'Selected Articles'),
          slugs: _s('intikhab-likina', 'maqala-intikhab', 'selected-articles')),
    ],
  ),
  FeedCategory(
      id: 'world-media',
      labels: _l('نړیوالي رسنۍ', 'رسانه‌های جهانی', 'Global Media'),
      slugs: _s('world-media', 'world-media', 'global-media')),
  FeedCategory(
      id: 'raz',
      labels: _l('راز', 'راز', 'Secret'),
      slugs: _s('raaz', 'raaz', 'secret')),
  FeedCategory(
      id: 'tabyin',
      labels: _l('تبین', 'تبیین', 'Clarification'),
      slugs: _s('تبین', 'تبین', 'clarification')),
  FeedCategory(
      id: 'dark-faces',
      labels: _l('تورې څېرې', 'نفرین‌شدگان', 'Dark Faces'),
      slugs: _s('تورې-څېرې', 'نفرین-شدگان', 'dark-faces')),
  FeedCategory(
      id: 'videos',
      labels: _l('ویډیوګانې', 'ویدیوها', 'Videos'),
      slugs: _s('videos-2', 'videos-2', 'videos')),
];

final List<FeedCategory> kAllCategories = [
  for (final s in kSections) ...s.flattened(),
];

FeedCategory? categoryById(String id) {
  if (id == kHomeFeed.id) return kHomeFeed;
  for (final c in kAllCategories) {
    if (c.id == id) return c;
  }
  return null;
}
