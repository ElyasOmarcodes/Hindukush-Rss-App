import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Networking tuned for weak, high-latency connections.
///
/// The old code put a hard cap on the *whole* request (15–35s). On a slow but
/// working link a large response simply can't finish inside that window, so
/// every attempt was cut off and restarted from zero — the app reported "no
/// internet" while chat apps (tiny payloads) worked fine. Here the limits are
/// on *silence* instead: connecting and the first response byte must happen in
/// reasonable time, and after that the download may take as long as it needs
/// **as long as bytes keep arriving**.
class Net {
  Net._();

  /// How long to wait for the TCP/TLS connection.
  static const connectTimeout = Duration(seconds: 10);

  /// How long to wait for the response headers once connected.
  static const headersTimeout = Duration(seconds: 20);

  /// Longest allowed gap between two chunks of the body.
  static const stallTimeout = Duration(seconds: 20);

  /// One tuned client. A connect timeout matters on mobile: without it a dead
  /// route can hang for minutes at the OS level before failing over.
  static http.Client createClient() {
    final io = HttpClient()
      ..connectionTimeout = connectTimeout
      ..idleTimeout = const Duration(seconds: 30)
      ..maxConnectionsPerHost = 4
      ..autoUncompress = true; // sends Accept-Encoding: gzip, inflates for us
    return IOClient(io);
  }

  /// GET with retries and stall-based (not total) timeouts.
  ///
  /// 4xx responses are final; network errors, stalls and 5xx are retried with
  /// a short backoff.
  static Future<http.Response> get(
    http.Client client,
    String url, {
    Map<String, String> headers = const {},
    int attempts = 2,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < attempts; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 700 * attempt));
      }
      try {
        final request = http.Request('GET', Uri.parse(url))
          ..headers.addAll(headers);
        final streamed = await client.send(request).timeout(headersTimeout);
        final bytes =
            await http.ByteStream(streamed.stream.timeout(stallTimeout))
                .toBytes();
        final response = http.Response.bytes(
          bytes,
          streamed.statusCode,
          headers: streamed.headers,
          request: request,
        );
        if (response.statusCode == 200) return response;
        if (response.statusCode >= 400 && response.statusCode < 500) {
          throw HttpStatusError(response.statusCode, url);
        }
        lastError = HttpStatusError(response.statusCode, url);
      } on HttpStatusError {
        rethrow;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? HttpStatusError(0, url);
  }
}

/// A non-200 response. 4xx is thrown immediately (retrying can't help).
class HttpStatusError implements Exception {
  HttpStatusError(this.status, this.url);
  final int status;
  final String url;
  @override
  String toString() => 'HTTP $status for $url';
}

/// Caps how many downloads run at once, so a screenful of thumbnails can't
/// saturate a thin connection and starve the request the user is waiting on.
class TaskPool {
  TaskPool(this.max);
  final int max;
  int _running = 0;
  final _waiting = <Completer<void>>[];

  Future<T> run<T>(Future<T> Function() task) async {
    if (_running >= max) {
      final slot = Completer<void>();
      _waiting.add(slot);
      await slot.future;
    }
    _running++;
    try {
      return await task();
    } finally {
      _running--;
      // Newest first: the most recently requested image is the one most
      // likely to be on screen right now.
      if (_waiting.isNotEmpty) _waiting.removeLast().complete();
    }
  }
}
