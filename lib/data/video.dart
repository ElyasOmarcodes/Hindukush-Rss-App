import 'models/article.dart';

/// Detects video content in an article: a YouTube embed or a self-hosted mp4.
class VideoInfo {
  const VideoInfo({this.youtubeId, this.mp4Url});

  final String? youtubeId;
  final String? mp4Url;

  bool get isVideo => youtubeId != null || mp4Url != null;

  String? get youtubeWatchUrl =>
      youtubeId != null ? 'https://www.youtube.com/watch?v=$youtubeId' : null;

  /// Thumbnail: YouTube's poster when available, else the featured image.
  String? thumbnail(String? fallback) => youtubeId != null
      ? 'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg'
      : fallback;

  static final _yt = RegExp(
    r'(?:youtube\.com/(?:watch\?v=|embed/|v/|shorts/)|youtu\.be/)([A-Za-z0-9_-]{11})',
    caseSensitive: false,
  );
  static final _mp4 = RegExp(
    r'''https?://[^\s"'<>]+\.mp4''',
    caseSensitive: false,
  );

  static VideoInfo detect(Article a) {
    final hay = '${a.contentHtml}\n${a.link}';
    final yt = _yt.firstMatch(hay)?.group(1);
    final mp4 = _mp4.firstMatch(a.contentHtml)?.group(0);
    return VideoInfo(youtubeId: yt, mp4Url: mp4);
  }
}
