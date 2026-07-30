import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/feeds.dart';
import '../../core/localization/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import '../widgets/brand_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _appId = 'com.hindukush.hindukush';
  static const _privacyUrl = 'https://hindukushpa.com/privacy-policy/';
  static const _bugEmail = 'elyasomar001@gmail.com';

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppScope.of(context).language;
    final s = S.of(lang);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: scheme.surface,
            surfaceTintColor: Colors.transparent,
            title: Text(s.aboutTitle),
          ),
          SliverList.list(children: [
            // Brand header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppTheme.rLarge),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: BrandLogo(color: scheme.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(s.appName,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    s.aboutDescription,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            _title(theme, s.aboutSites),
            for (final l in AppLanguage.values)
              _SiteCard(
                title: l.nativeName,
                url: l.baseUrl,
                onTap: () => _open(l.baseUrl),
              ),

            const SizedBox(height: 8),
            _title(theme, s.aboutTitle),
            _tile(scheme, Icons.privacy_tip_outlined, s.privacyPolicy,
                () => _open(_privacyUrl)),
            _tile(scheme, Icons.star_outline_rounded, s.rateApp,
                () => _open('https://play.google.com/store/apps/details?id=$_appId')),
            _tile(scheme, Icons.bug_report_outlined, s.reportBug, () {
              _open(
                  'mailto:$_bugEmail?subject=${Uri.encodeComponent('Hindukush app — bug report')}');
            }),

            const SizedBox(height: 16),
            Center(
              child: Text(
                '${s.version} 1.0.0',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 110),
          ]),
        ],
      ),
    );
  }

  Widget _title(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
        child: Text(text,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            )),
      );

  Widget _tile(
          ColorScheme scheme, IconData icon, String title, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Material(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: Icon(icon),
            title: Text(title),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onTap,
          ),
        ),
      );
}

class _SiteCard extends StatelessWidget {
  const _SiteCard(
      {required this.title, required this.url, required this.onTap});
  final String title;
  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.language_rounded,
                    color: scheme.onSecondaryContainer),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSecondaryContainer)),
                      Text(url.replaceAll('https://', ''),
                          style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSecondaryContainer
                                  .withValues(alpha: 0.8))),
                    ],
                  ),
                ),
                Icon(Icons.open_in_new_rounded,
                    size: 18, color: scheme.onSecondaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
