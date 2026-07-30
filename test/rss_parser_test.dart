import 'package:flutter_test/flutter_test.dart';
import 'package:hindukush/data/rss/rss_parser.dart';

const _sample = '''
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"
  xmlns:content="http://purl.org/rss/1.0/modules/content/"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:media="http://search.yahoo.com/mrss/">
  <channel>
    <title>هندوکش غږ</title>
    <item>
      <title>د ازموینې سرلیک</title>
      <link>https://hindukushpa.com/test-post/</link>
      <dc:creator>احمد</dc:creator>
      <pubDate>Wed, 30 Jul 2025 14:22:05 +0000</pubDate>
      <guid isPermaLink="false">https://hindukushpa.com/?p=123</guid>
      <description>دا لنډه پیژندنه ده.</description>
      <content:encoded><![CDATA[<p>دا اصلي متن دی.</p><img src="https://hindukushpa.com/img.jpg"/>]]></content:encoded>
      <category>افغانستان</category>
      <media:thumbnail url="https://hindukushpa.com/thumb.jpg"/>
    </item>
  </channel>
</rss>
''';

void main() {
  test('parses a WordPress RSS item', () {
    final articles = RssParser.parse(_sample, categoryId: 'afghanistan');
    expect(articles, hasLength(1));
    final a = articles.first;
    expect(a.title, 'د ازموینې سرلیک');
    expect(a.link, 'https://hindukushpa.com/test-post/');
    expect(a.author, 'احمد');
    expect(a.categoryId, 'afghanistan');
    expect(a.categories, contains('افغانستان'));
    expect(a.published, isNotNull);
    expect(a.published!.year, 2025);
    expect(a.contentHtml, contains('اصلي متن'));
    // image resolved from media:thumbnail or the inline <img>.
    expect(a.imageUrl, isNotNull);
    expect(a.summary, contains('لنډه'));
  });

  test('ignores non-item content gracefully', () {
    final articles = RssParser.parse(
      '<rss version="2.0"><channel><title>x</title></channel></rss>',
    );
    expect(articles, isEmpty);
  });
}
