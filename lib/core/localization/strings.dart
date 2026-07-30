import '../config/feeds.dart';

/// Lightweight, dependency-free UI string table keyed by [AppLanguage].
/// Content labels (categories) live in `feeds.dart`; these are the app's own
/// chrome strings.
class S {
  S._(this.lang);
  final AppLanguage lang;

  static S of(AppLanguage lang) => S._(lang);

  String _p(String ps, String fa, String en) => switch (lang) {
        AppLanguage.pashto => ps,
        AppLanguage.dari => fa,
        AppLanguage.english => en,
      };

  // Brand
  String get appName => _p('هندوکش غږ', 'هندوکش غږ', 'Hindukush Ghag');
  String get splashTitle => _p('هندوکش غږ', 'هندوکش غږ', 'Hindukush Ghag');
  String get splashSubtitle =>
      _p('کره خبرونه زمونږ رسالت دی', 'اخبار دقیق رسالت ماست', 'Accurate news is our mission');

  // Navigation bar
  String get navHome => _p('کورپاڼه', 'خانه', 'Home');
  String get navLatest => _p('نوي', 'تازه', 'Latest');
  String get navFavorites => _p('خوښ شوي', 'علاقه‌مندی‌ها', 'Favorites');
  String get navSettings => _p('تنظیمات', 'تنظیمات', 'Settings');
  String get navAbout => _p('په اړه', 'درباره', 'About');

  // Common
  String get search => _p('لټون', 'جستجو', 'Search');
  String get searchProduct => _p('خبر ولټوه', 'جستجوی خبر', 'Search news');
  String get retry => _p('بیا هڅه', 'تلاش دوباره', 'Retry');
  String get loading => _p('بارول کیږي…', 'در حال بارگذاری…', 'Loading…');
  String get empty => _p('هیڅ مطلب نشته', 'موردی یافت نشد', 'Nothing here yet');
  String get errorGeneric =>
      _p('یوه ستونزه رامنځته شوه', 'مشکلی پیش آمد', 'Something went wrong');
  String get offline =>
      _p('انټرنیټ نشته — ساتل شوي مطالب ښکاره کیږي', 'اینترنت نیست — مطالب ذخیره‌شده', 'Offline — showing saved items');
  String get by => _p('لیکوال:', 'نویسنده:', 'By');

  // Sections
  String get sectionsTitle => _p('برخې', 'بخش‌ها', 'Sections');
  String get latestTitle => _p('نوي مطالب', 'تازه‌ترین‌ها', 'Latest');
  String get favoritesTitle => _p('خوښ شوي مطالب', 'علاقه‌مندی‌ها', 'Favorites');
  String get favoritesEmpty =>
      _p('تر اوسه دې هیڅ مطلب نه دی خوښ کړی', 'هنوز چیزی ذخیره نکرده‌اید', 'You haven\'t saved anything yet');

  // Post view / reading toolbar
  String get copy => _p('کاپي', 'کپی', 'Copy');
  String get shareAction => _p('شریکول', 'اشتراک', 'Share');
  String get addFavorite => _p('خوښول', 'ذخیره', 'Save');
  String get removeFavorite => _p('لرې کول', 'حذف از ذخیره', 'Unsave');
  String get quickSettings => _p('چټک تنظیمات', 'تنظیمات سریع', 'Quick settings');
  String get copied => _p('کاپي شو', 'کپی شد', 'Copied');
  String get openInBrowser => _p('په براوزر کې پرانیستل', 'باز کردن در مرورگر', 'Open in browser');

  // Quick settings sheet
  String get fontSize => _p('د لیکنې سایز', 'اندازه متن', 'Font size');
  String get lineHeight => _p('د لاینونو فاصله', 'فاصله خطوط', 'Line spacing');
  String get textAlign => _p('د متن ترتیب', 'ترازبندی متن', 'Text alignment');
  String get alignStart => _p('پیل', 'راست', 'Start');
  String get alignCenter => _p('مینځ', 'وسط', 'Center');
  String get alignJustify => _p('عادل', 'همتراز', 'Justify');

  // Settings screen
  String get settingsTitle => _p('تنظیمات', 'تنظیمات', 'Settings');
  String get language => _p('د پروګرام ژبه', 'زبان برنامه', 'App language');
  String get appearance => _p('بڼه', 'ظاهر', 'Appearance');
  String get accentColor => _p('اصلي رنګ', 'رنگ اصلی', 'Accent color');
  String get notifications => _p('خبرتیاوې', 'اعلان‌ها', 'Notifications');
  String get notificationsSub => _p('د نویو خبرونو خبرتیا ترلاسه کړه',
      'دریافت اعلان برای اخبار جدید', 'Get notified about new articles');
  String get sectionAppearance => _p('بڼه او رنګ', 'ظاهر و رنگ', 'Appearance');
  String get sectionContent => _p('محتوا او افلاین', 'محتوا و آفلاین', 'Content & offline');
  String get sectionGeneral => _p('عمومي', 'عمومی', 'General');
  String get themeLight => _p('روښانه', 'روشن', 'Light');
  String get themeDark => _p('تیاره', 'تاریک', 'Dark');
  String get themeSystem => _p('سیستم', 'سیستم', 'System');
  String get offlineDb => _p('افلاین ډیټابیس ساتل', 'ذخیره پایگاه‌داده آفلاین', 'Keep offline database');
  String get autoDeleteNews =>
      _p('د خبرونو د اتومات حذف وخت', 'زمان حذف خودکار اخبار', 'Auto-delete news after');
  String get autoDeleteRead =>
      _p('د لوستل شویو د اتومات حذف وخت', 'زمان حذف خبرهای خوانده‌شده', 'Auto-delete read news after');
  String get storedCount => _p('ساتل شوي مطالب', 'موارد ذخیره‌شده', 'Stored items');
  String get clearCache => _p('ډیټابیس پاکول', 'پاک کردن پایگاه‌داده', 'Clear database');
  String get cleared => _p('پاک شو', 'پاک شد', 'Cleared');

  String days(int n) => _p('$n ورځې', '$n روز', '$n days');
  String get never => _p('هیڅکله', 'هرگز', 'Never');
  String items(int n) => _p('$n مطالب', '$n مورد', '$n items');

  // About screen
  String get aboutTitle => _p('په اړه', 'درباره', 'About');
  String get aboutSites => _p('د هندوکش غږ ویب‌پاڼې', 'وب‌سایت‌های هندوکش غږ', 'Hindukush Ghag websites');
  String get privacyPolicy => _p('د محرمیت تګلاره', 'سیاست حریم خصوصی', 'Privacy Policy');
  String get rateApp => _p('پروګرام ته ستوري ورکړئ', 'به برنامه امتیاز دهید', 'Rate the app');
  String get reportBug => _p('د ستونزې راپور', 'گزارش مشکل', 'Report a bug');
  String get version => _p('نسخه', 'نسخه', 'Version');
  String get aboutDescription => _p(
        'هندوکش غږ یوه خپلواکه رسنۍ ده چې کره خبرونه یې رسالت دی.',
        'هندوکش غږ یک رسانه مستقل است که اخبار دقیق رسالت آن است.',
        'Hindukush Ghag is an independent outlet whose mission is accurate news.',
      );
}
