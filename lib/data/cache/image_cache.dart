import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// A small, cross-platform (Android/iOS/Windows) disk + memory image cache.
///
/// Fixes two problems:
///   * images re-downloading every time a row scrolls back into view
///     (served instantly from the in-memory LRU / disk instead), and
///   * images not appearing offline (read from disk when the network is down).
///
/// Pure Dart — no native SQLite/cache-manager dependency.
class DiskImageCache {
  DiskImageCache._();
  static final DiskImageCache instance = DiskImageCache._();

  Directory? _dir;
  final _client = http.Client();

  /// In-memory LRU of decoded bytes so re-shown images never touch disk/network.
  final _mem = <String, Uint8List>{};
  static const _memMax = 80;

  final _inflight = <String, Future<Uint8List?>>{};

  Future<void> init() async {
    try {
      final base = await getApplicationSupportDirectory();
      final d = Directory('${base.path}/hindukush_images');
      if (!await d.exists()) await d.create(recursive: true);
      _dir = d;
    } catch (_) {
      _dir = null; // memory-only if disk isn't available
    }
  }

  /// Synchronous peek — returns bytes only if already in memory (no I/O).
  Uint8List? peek(String? url) {
    if (url == null || url.isEmpty) return null;
    return _mem[url];
  }

  /// Returns bytes for [url] from memory → disk → network, caching along the way.
  Future<Uint8List?> load(String? url) {
    if (url == null || url.isEmpty) return Future.value(null);
    final cached = _mem[url];
    if (cached != null) return Future.value(cached);
    return _inflight[url] ??= _loadUncached(url).whenComplete(() {
      _inflight.remove(url);
    });
  }

  Future<Uint8List?> _loadUncached(String url) async {
    final file = _fileFor(url);
    // disk
    if (file != null && await file.exists()) {
      try {
        final bytes = await file.readAsBytes();
        _remember(url, bytes);
        return bytes;
      } catch (_) {/* fall through to network */}
    }
    // network
    try {
      final resp = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        final bytes = resp.bodyBytes;
        _remember(url, bytes);
        if (file != null) {
          unawaited(file.writeAsBytes(bytes, flush: false));
        }
        return bytes;
      }
    } catch (_) {/* offline / failed */}
    return null;
  }

  void _remember(String url, Uint8List bytes) {
    _mem.remove(url);
    _mem[url] = bytes;
    if (_mem.length > _memMax) {
      _mem.remove(_mem.keys.first);
    }
  }

  File? _fileFor(String url) {
    final dir = _dir;
    if (dir == null) return null;
    return File('${dir.path}/${_hash(url)}.img');
  }

  /// A stable 53-bit hash → collision-safe filename.
  static String _hash(String s) {
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x1FFFFFFFFFFFFF;
    }
    return h.toRadixString(16);
  }
}
