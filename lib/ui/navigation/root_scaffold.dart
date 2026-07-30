import 'package:flutter/material.dart';

import '../../core/localization/strings.dart';
import '../../state/app_state.dart';
import '../about/about_screen.dart';
import '../favorites/favorites_screen.dart';
import '../home/home_screen.dart';
import '../latest/latest_screen.dart';
import '../settings/settings_screen.dart';
import 'floating_nav_bar.dart';

/// Hosts the five primary destinations behind a floating Expressive nav bar.
class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _index = 0;

  static const _pages = [
    HomeScreen(),
    LatestScreen(),
    FavoritesScreen(),
    SettingsScreen(),
    AboutScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final s = S.of(AppScope.of(context).language);
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(_index),
            child: _pages[_index],
          ),
        ),
      ),
      bottomNavigationBar: FloatingNavBar(
        selectedIndex: _index,
        onSelect: (i) => setState(() => _index = i),
        destinations: [
          NavDest(Icons.home_outlined, Icons.home_rounded, s.navHome),
          NavDest(Icons.auto_awesome_outlined, Icons.auto_awesome_rounded,
              s.navLatest),
          NavDest(Icons.bookmark_outline_rounded, Icons.bookmark_rounded,
              s.navFavorites),
          NavDest(Icons.tune_outlined, Icons.tune_rounded, s.navSettings),
          NavDest(Icons.info_outline_rounded, Icons.info_rounded, s.navAbout),
        ],
      ),
    );
  }
}
