import 'package:flutter/material.dart';

import '../../core/config/feeds.dart';
import '../../core/localization/strings.dart';
import '../../data/models/article.dart';
import '../../services.dart';
import '../navigation/routes.dart';
import '../widgets/article_tile.dart';

/// In-app search over cached articles — **title only** (per spec).
class ArticleSearchDelegate extends SearchDelegate<void> {
  ArticleSearchDelegate(this.lang, {List<Article>? scope})
      : _scope = scope,
        super(searchFieldLabel: S.of(lang).search);

  final AppLanguage lang;
  final List<Article>? _scope;

  List<Article> get _all => _scope ?? appRepository.allCached(lang);

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: Icon(lang.isRtl ? Icons.arrow_forward : Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _list(context);

  @override
  Widget buildSuggestions(BuildContext context) => _list(context);

  Widget _list(BuildContext context) {
    final s = S.of(lang);
    final q = query.trim().toLowerCase();
    final results = q.isEmpty
        ? const <Article>[]
        : _all
            .where((a) => a.title.toLowerCase().contains(q))
            .toList();

    if (q.isEmpty) {
      return _hint(context, Icons.search_rounded, s.search);
    }
    if (results.isEmpty) {
      return _hint(context, Icons.inbox_outlined, s.empty);
    }
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(indent: 114),
      itemBuilder: (context, i) {
        final a = results[i];
        return ArticleTile(
          article: a,
          lang: lang,
          read: appRepository.isRead(a.id),
          onTap: () {
            close(context, null);
            openPost(context, a);
          },
        );
      },
    );
  }

  Widget _hint(BuildContext context, IconData icon, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
