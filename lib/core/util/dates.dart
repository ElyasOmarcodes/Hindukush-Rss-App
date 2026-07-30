import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../config/feeds.dart';

/// Localised, human-friendly date helpers.
///
/// Pashto & Dari use the Hijri-Shamsi (Jalali) calendar; English uses Gregorian.
class Dates {
  static const _faMonths = [
    'حمل', 'ثور', 'جوزا', 'سرطان', 'اسد', 'سنبله',
    'میزان', 'عقرب', 'قوس', 'جدی', 'دلو', 'حوت',
  ];

  static String absolute(DateTime? d, AppLanguage lang) {
    if (d == null) return '';
    final local = d.toLocal();
    if (lang == AppLanguage.english) {
      return DateFormat.yMMMMd('en').add_jm().format(local);
    }
    // Jalali (Hijri-Shamsi) for Pashto & Dari.
    final j = Jalali.fromDateTime(local);
    final month = _faMonths[j.month - 1];
    final time = DateFormat.Hm('en').format(local);
    return '${j.day} $month ${j.year}  •  $time';
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
