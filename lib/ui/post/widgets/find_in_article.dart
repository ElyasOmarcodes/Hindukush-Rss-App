import 'package:flutter/material.dart';

/// One occurrence of the query: which paragraph it's in and where.
class FindMatch {
  const FindMatch(this.paragraph, this.start, this.end);
  final int paragraph;
  final int start;
  final int end;
}

/// Locates every case-insensitive occurrence of [query] across [paragraphs].
List<FindMatch> findMatches(List<String> paragraphs, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return const [];
  final out = <FindMatch>[];
  for (var p = 0; p < paragraphs.length; p++) {
    final hay = paragraphs[p].toLowerCase();
    var i = hay.indexOf(needle);
    while (i != -1) {
      out.add(FindMatch(p, i, i + needle.length));
      i = hay.indexOf(needle, i + needle.length);
      if (out.length > 1000) return out;
    }
  }
  return out;
}

/// A paragraph of article text with every match highlighted, and the currently
/// focused match highlighted more strongly.
class HighlightedParagraph extends StatelessWidget {
  const HighlightedParagraph({
    super.key,
    required this.text,
    required this.matches,
    required this.style,
    required this.textAlign,
    this.activeMatch,
  });

  final String text;

  /// Matches that fall inside this paragraph, in order.
  final List<FindMatch> matches;
  final TextStyle style;
  final TextAlign textAlign;

  /// The match (within [matches]) that is currently selected, if any.
  final FindMatch? activeMatch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (matches.isEmpty) {
      return Text(text, style: style, textAlign: textAlign);
    }

    final spans = <TextSpan>[];
    var cursor = 0;
    for (final m in matches) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, m.start)));
      }
      final isActive = activeMatch != null &&
          activeMatch!.paragraph == m.paragraph &&
          activeMatch!.start == m.start;
      spans.add(TextSpan(
        text: text.substring(m.start, m.end),
        style: TextStyle(
          color: isActive ? scheme.onPrimary : scheme.onPrimaryContainer,
          backgroundColor:
              isActive ? scheme.primary : scheme.primaryContainer,
          fontWeight: FontWeight.w800,
        ),
      ));
      cursor = m.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return Text.rich(
      TextSpan(style: style, children: spans),
      textAlign: textAlign,
    );
  }
}
