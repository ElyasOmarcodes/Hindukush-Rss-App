import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/localization/strings.dart';
import '../../state/app_state.dart';

/// The hosted privacy policy, opened inside the app.
///
/// On Android / iOS it loads the live page in an in-app [WebView]. Desktop
/// (Windows) has no WebView implementation, so it fetches the page and renders
/// it with [HtmlWidget], with an "open in browser" fallback if that fails.
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  static const url =
      'https://elyasomarcodes.github.io/Hindukush-Rss-App/privacy-policy.html';

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool get _webViewSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  WebViewController? _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (_webViewSupported) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
          ),
        )
        ..loadRequest(Uri.parse(PrivacyPolicyScreen.url));
    }
  }

  Future<void> _openExternally() async {
    final uri = Uri.parse(PrivacyPolicyScreen.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(AppScope.of(context).language);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.privacyPolicy),
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: s.openInBrowser,
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: _openExternally,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _webViewSupported
          ? Stack(
              children: [
                WebViewWidget(controller: _controller!),
                if (_loading)
                  const LinearProgressIndicator(minHeight: 3),
              ],
            )
          : _DesktopFallback(scheme: scheme, s: s, onOpen: _openExternally),
    );
  }
}

/// Fetches and renders the policy HTML for platforms without a WebView.
class _DesktopFallback extends StatefulWidget {
  const _DesktopFallback(
      {required this.scheme, required this.s, required this.onOpen});
  final ColorScheme scheme;
  final S s;
  final Future<void> Function() onOpen;

  @override
  State<_DesktopFallback> createState() => _DesktopFallbackState();
}

class _DesktopFallbackState extends State<_DesktopFallback> {
  late Future<String> _future = _fetch();

  Future<String> _fetch() async {
    final res =
        await http.get(Uri.parse(PrivacyPolicyScreen.url)).timeout(
              const Duration(seconds: 15),
            );
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }
    return res.body;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    return FutureBuilder<String>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError || snap.data == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded,
                    size: 48, color: scheme.onSurfaceVariant),
                const SizedBox(height: 12),
                Text(widget.s.errorGeneric,
                    style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: widget.onOpen,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(widget.s.openInBrowser),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      setState(() => _future = _fetch()),
                  child: Text(widget.s.retry),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: HtmlWidget(
            snap.data!,
            textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.55,
                  color: scheme.onSurface,
                ),
          ),
        );
      },
    );
  }
}
