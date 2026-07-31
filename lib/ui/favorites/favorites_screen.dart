import 'package:flutter/material.dart';

import '../../core/localization/strings.dart';
import '../../data/models/article.dart';
import '../../services.dart';
import '../../state/app_state.dart';
import '../post/post_view_screen.dart';
import '../widgets/article_tile.dart';
import '../widgets/edge_fade.dart';

/// The "Favorites" tab — articles the user saved (kept forever, offline).
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late List<Article> _items = appRepository.favorites();

  void _reload() => setState(() => _items = appRepository.favorites());

  Future<void> _open(Article a) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostViewScreen(article: a)),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppScope.of(context).language;
    final s = S.of(lang);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: scheme.surface,
            surfaceTintColor: Colors.transparent,
            title: Text(s.favoritesTitle),
          ),
          const SliverFadeUnderAppBar(),
          if (_items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark_border_rounded,
                        size: 60, color: scheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text(s.favoritesEmpty,
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final a = _items[i];
                return ArticleTile(
                  article: a,
                  lang: lang,
                  read: appRepository.isRead(a.id),
                  onTap: () => _open(a),
                );
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }
}
