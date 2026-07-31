/// Turns WordPress `content:encoded` HTML into readable plain text — used by
/// the in-article find and by the "copy article" action.
String htmlToPlainText(String html) {
  var t = html;
  t = t.replaceAll(
      RegExp(r'<script[^>]*>.*?</script>', dotAll: true, caseSensitive: false),
      ' ');
  t = t.replaceAll(
      RegExp(r'<style[^>]*>.*?</style>', dotAll: true, caseSensitive: false),
      ' ');
  t = t.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  t = t.replaceAll(
      RegExp(r'</(p|div|h[1-6]|li|tr|blockquote)>', caseSensitive: false),
      '\n\n');
  t = t.replaceAll(RegExp(r'<[^>]+>'), ' ');

  // Numeric entities, then the handful of named ones that actually show up.
  t = t.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
    final code = int.tryParse(m[1]!);
    return code == null ? m[0]! : String.fromCharCode(code);
  });
  const named = {
    '&nbsp;': ' ',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&apos;': "'",
    '&hellip;': '…',
    '&mdash;': '—',
    '&ndash;': '–',
    '&laquo;': '«',
    '&raquo;': '»',
    '&rsquo;': '’',
    '&lsquo;': '‘',
    '&ldquo;': '“',
    '&rdquo;': '”',
  };
  named.forEach((k, v) => t = t.replaceAll(k, v));

  t = t.replaceAll(RegExp(r'[ \t ]+'), ' ');
  t = t.replaceAll(RegExp(r' *\n *'), '\n');
  t = t.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return t.trim();
}

/// Splits article text into paragraphs, dropping empties. The find view renders
/// one widget per paragraph so it can scroll a specific match into view.
List<String> htmlToParagraphs(String html) => [
      for (final p in htmlToPlainText(html).split('\n'))
        if (p.trim().isNotEmpty) p.trim(),
    ];
