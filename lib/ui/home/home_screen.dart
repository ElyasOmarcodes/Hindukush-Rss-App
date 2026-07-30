import 'package:flutter/material.dart';

import '../../core/config/feeds.dart';
import '../../core/localization/strings.dart';
import '../../data/models/article.dart';
import '../../services.dart';
import '../../state/app_state.dart';
import '../navigation/routes.dart';
import '../widgets/contained_loading_indicator.dart';
import 'widgets/category_card.dart';
import 'widgets/news_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Article> _latest = [];
  bool _loading = true;
  AppLanguage? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = AppScope.of(context).language;
    if (_loadedFor != lang) {
      _loadedFor = lang;
      _load(lang);
    }
  }

  Future<void> _load(AppLanguage lang) async {
    setState(() => _loading = true);
    final result = await appRepository.loadLatest(
      lang,
      keepOffline: AppScope.read(context).keepOffline,
    );
    if (!mounted) return;
    setState(() {
      _latest = result.articles;
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    final lang = AppScope.read(context).language;
    await _load(lang);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lang = app.language;
    final s = S.of(lang);
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _refresh,
      displacement: 28,
      edgeOffset: 8,
      color: scheme.onSecondaryContainer,
      backgroundColor: scheme.secondaryContainer,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                s.appName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
              ),
            ),
          ),
          if (_loading && _latest.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: CenteredLoading(),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: NewsCarousel(
                articles: _latest,
                lang: lang,
                onTap: (a) => openPost(context, a),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                child: Text(
                  s.sectionsTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.list(children: _buildCategoryCards(context, lang)),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildCategoryCards(BuildContext context, AppLanguage lang) {
    final widgets = <Widget>[];
    var color = 0;
    for (final section in kSections) {
      if (!section.availableFor(lang)) continue;
      widgets.add(CategoryCard(
        category: section,
        lang: lang,
        colorIndex: color++,
        onTap: () => openCategory(context, section),
      ));
      for (final child in section.children) {
        if (!child.availableFor(lang)) continue;
        widgets.add(CategoryCard(
          category: child,
          lang: lang,
          colorIndex: color++,
          inset: true,
          onTap: () => openCategory(context, child),
        ));
      }
    }
    return widgets;
  }
}
