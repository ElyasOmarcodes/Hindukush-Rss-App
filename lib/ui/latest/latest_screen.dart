import 'package:flutter/material.dart';

import '../../core/config/feeds.dart';
import '../../core/localization/strings.dart';
import '../../state/app_state.dart';
import '../list/list_screen.dart';

/// The "Latest" tab — the site's main feed rendered as a vertical list.
class LatestScreen extends StatelessWidget {
  const LatestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(AppScope.of(context).language);
    return ListScreen(
      category: kHomeFeed,
      titleOverride: s.latestTitle,
    );
  }
}
