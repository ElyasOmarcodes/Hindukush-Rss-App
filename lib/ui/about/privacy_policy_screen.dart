import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../../core/localization/strings.dart';
import '../../state/app_state.dart';

/// Renders the bundled privacy policy inside the app (an in-app document page).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(AppScope.of(context).language);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.privacyPolicy),
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('assets/privacy_policy.html'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            child: HtmlWidget(
              snapshot.data!,
              textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.55,
                    color: scheme.onSurface,
                  ),
            ),
          );
        },
      ),
    );
  }
}
