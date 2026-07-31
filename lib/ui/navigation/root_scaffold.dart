import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/strings.dart';
import '../../state/app_state.dart';
import '../favorites/favorites_screen.dart';
import '../home/home_screen.dart';
import '../latest/latest_screen.dart';
import '../settings/settings_screen.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/edge_fade.dart';
import 'floating_nav_bar.dart';

/// Hosts the five primary destinations behind a floating Expressive nav bar.
class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _index = 0;

  void _goToLatest() => setState(() => _index = 1);

  List<Widget> get _pages => [
        HomeScreen(onSeeAll: _goToLatest),
        const LatestScreen(),
        const FavoritesScreen(),
        const SettingsScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    final s = S.of(AppScope.of(context).language);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // Back on a sub-tab returns to Home; on Home, confirm exit.
        if (_index != 0) {
          setState(() => _index = 0);
          return;
        }
        final ok = await showConfirmDialog(
          context,
          icon: Icons.exit_to_app_rounded,
          title: s.exitTitle,
          message: s.exitMsg,
          confirmLabel: s.exit,
        );
        if (ok) SystemNavigator.pop();
      },
      child: Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        // Home (index 0) has no app bar, so it gets a top fade too; the other
        // tabs fade content under their own app bars. Every tab shares the
        // bottom fade so content dissolves behind the floating nav bar.
        child: EdgeFade(
          top: _index == 0,
          bottomHeight: 118,
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
      ),
      bottomNavigationBar: FloatingNavBar(
        selectedIndex: _index,
        onSelect: (i) => setState(() => _index = i),
        destinations: [
          NavDest(Icons.home_outlined, Icons.home_rounded, s.navHome),
          NavDest(Icons.fiber_new_outlined, Icons.fiber_new_rounded,
              s.navLatest),
          NavDest(Icons.bookmark_outline_rounded, Icons.bookmark_rounded,
              s.navFavorites),
          NavDest(Icons.tune_outlined, Icons.tune_rounded, s.navSettings),
        ],
      ),
      ),
    );
  }
}
