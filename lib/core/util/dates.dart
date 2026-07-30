import 'package:intl/intl.dart';

import '../config/feeds.dart';

/// Localised, human-friendly date helpers.
class Dates {
  static String absolute(DateTime? d, AppLanguage lang) {
    if (d == null) return '';
    final locale = lang == AppLanguage.english ? 'en' : 'fa';
    return DateFormat.yMMMMd(locale).add_jm().format(d.toLocal());
  }

  static String relative(DateTime? d, AppLanguage lang) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d.toLocal());
    String p(String ps, String fa, String en) => switch (lang) {
          AppLanguage.pashto => ps,
          AppLanguage.dari => fa,
          AppLanguage.english => en,
        };
    if (diff.inMinutes < 1) return p('همدا اوس', 'همین حالا', 'just now');
    if (diff.inMinutes < 60) {
      final n = diff.inMinutes;
      return p('$n دقیقې مخکې', '$n دقیقه پیش', '${n}m ago');
    }
    if (diff.inHours < 24) {
      final n = diff.inHours;
      return p('$n ساعته مخکې', '$n ساعت پیش', '${n}h ago');
    }
    if (diff.inDays < 7) {
      final n = diff.inDays;
      return p('$n ورځې مخکې', '$n روز پیش', '${n}d ago');
    }
    return absolute(d, lang);
  }
}
