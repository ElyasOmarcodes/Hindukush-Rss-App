import 'package:flutter/material.dart';

import '../../core/config/feeds.dart';
import '../../core/localization/strings.dart';
import '../../data/models/article.dart';
import '../../services.dart';
import '../../state/app_state.dart';
import '../navigation/routes.dart';
import '../widgets/contained_loading_indicator.dart';
import '../widgets/expressive_refresh.dart';
import 'widgets/news_carousel.dart';
import 'widgets/section_list.dart';

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
    // Show any cached items instantly (offline-friendly first paint).
    final cache = appRepository.cachedFor(kHomeFeed);
    setState(() {
      if (_latest.isEmpty && cache.isNotEmpty) _latest = cache;
      _loading = _latest.isEmpty;
    });
    final result = await appRepository.loadLatest(
      lang,
      keepOffline: AppScope.read(context).keepOffline,
    );
    if (!mounted) return;
    setState(() {
      if (result.articles.isNotEmpty) _latest = result.articles;
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

    return ExpressiveRefresh(
      onRefresh: _refresh,
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: SectionList(lang: lang),
              ),
            ),
          ],
          // Clearance for the floating navigation bar.
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }
}
