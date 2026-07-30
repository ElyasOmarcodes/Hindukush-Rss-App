import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/feeds.dart';
import '../data/db/database.dart';

/// Reading-text alignment options exposed in the quick-settings sheet.
enum ReadingAlign { start, center, justify }

/// Global, persisted app settings + language/theme. A single [ChangeNotifier]
/// the whole app listens to.
class AppState extends ChangeNotifier {
  AppState(this._prefs, this._db);

  final SharedPreferences _prefs;
  final NewsDatabase _db;

  // ---- keys ----
  static const _kLang = 'lang';
  static const _kTheme = 'themeMode';
  static const _kOffline = 'keepOffline';
  static const _kDelNews = 'autoDeleteNewsDays';
  static const _kDelRead = 'autoDeleteReadDays';
  static const _kFont = 'readFontScale';
  static const _kLine = 'readLineHeight';
  static const _kAlign = 'readAlign';
  static const _kSeed = 'seedColor';
  static const _kNotif = 'notifications';

  static const int _defaultSeed = 0xFF6750A4;

  AppLanguage _language = AppLanguage.pashto;
  ThemeMode _themeMode = ThemeMode.system;
  bool _keepOffline = true;
  int _autoDeleteNewsDays = 14;
  int _autoDeleteReadDays = 3;
  double _fontScale = 1.0;
  double _lineHeight = 1.6;
  ReadingAlign _readingAlign = ReadingAlign.start;
  Color _seedColor = const Color(_defaultSeed);
  bool _notificationsEnabled = true;

  AppLanguage get language => _language;
  ThemeMode get themeMode => _themeMode;
  bool get keepOffline => _keepOffline;
  int get autoDeleteNewsDays => _autoDeleteNewsDays;
  int get autoDeleteReadDays => _autoDeleteReadDays;
  double get fontScale => _fontScale;
  double get lineHeight => _lineHeight;
  ReadingAlign get readingAlign => _readingAlign;
  Color get seedColor => _seedColor;
  bool get notificationsEnabled => _notificationsEnabled;

  Locale get locale => Locale(_language.code);
  TextDirection get textDirection =>
      _language.isRtl ? TextDirection.rtl : TextDirection.ltr;

  int get storedCount => _db.storedCount;

  void load() {
    _language = AppLanguageX.fromCode(_prefs.getString(_kLang));
    _themeMode = switch (_prefs.getString(_kTheme)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _keepOffline = _prefs.getBool(_kOffline) ?? true;
    _autoDeleteNewsDays = _prefs.getInt(_kDelNews) ?? 14;
    _autoDeleteReadDays = _prefs.getInt(_kDelRead) ?? 3;
    _fontScale = _prefs.getDouble(_kFont) ?? 1.0;
    _lineHeight = _prefs.getDouble(_kLine) ?? 1.6;
    _readingAlign = ReadingAlign.values[_prefs.getInt(_kAlign) ?? 0];
    _seedColor = Color(_prefs.getInt(_kSeed) ?? _defaultSeed);
    _notificationsEnabled = _prefs.getBool(_kNotif) ?? true;
    notifyListeners();
  }

  Future<void> setSeedColor(Color color) async {
    _seedColor = color;
    await _prefs.setInt(_kSeed, color.toARGB32());
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _prefs.setBool(_kNotif, value);
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage lang) async {
    if (_language == lang) return;
    _language = lang;
    await _prefs.setString(_kLang, lang.code);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_kTheme, mode.name);
    notifyListeners();
  }

  Future<void> setKeepOffline(bool value) async {
    _keepOffline = value;
    await _prefs.setBool(_kOffline, value);
    notifyListeners();
  }

  Future<void> setAutoDeleteNewsDays(int days) async {
    _autoDeleteNewsDays = days;
    await _prefs.setInt(_kDelNews, days);
    notifyListeners();
  }

  Future<void> setAutoDeleteReadDays(int days) async {
    _autoDeleteReadDays = days;
    await _prefs.setInt(_kDelRead, days);
    notifyListeners();
  }

  // Reading preferences (applied live in the post view).
  void setFontScale(double v) {
    _fontScale = v;
    _prefs.setDouble(_kFont, v);
    notifyListeners();
  }

  void setLineHeight(double v) {
    _lineHeight = v;
    _prefs.setDouble(_kLine, v);
    notifyListeners();
  }

  void setReadingAlign(ReadingAlign a) {
    _readingAlign = a;
    _prefs.setInt(_kAlign, a.index);
    notifyListeners();
  }

  Future<void> runRetention() async {
    if (!_keepOffline) {
      await _db.clearCache();
      notifyListeners();
      return;
    }
    await _db.applyRetention(
      newsMaxDays: _autoDeleteNewsDays,
      readMaxDays: _autoDeleteReadDays,
    );
    notifyListeners();
  }

  Future<void> clearDatabase() async {
    await _db.clearCache();
    notifyListeners();
  }
}

/// Inherited access to [AppState] for the whole widget tree.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in context');
    return scope!.notifier!;
  }

  /// Read without subscribing to rebuilds.
  static AppState read(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<AppScope>();
    return scope!.notifier!;
  }
}
