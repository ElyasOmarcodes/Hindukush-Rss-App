import 'package:flutter/material.dart';

import '../../core/localization/strings.dart';
import '../../state/app_state.dart';
import 'contained_loading_indicator.dart';

/// The loading indicator, plus a reassuring line that fades in if loading is
/// taking a while — on a weak connection silence reads as "broken", a note
/// that we're still trying reads as "slow".
class LoadingWithSlowHint extends StatefulWidget {
  const LoadingWithSlowHint({super.key});

  @override
  State<LoadingWithSlowHint> createState() => _LoadingWithSlowHintState();
}

class _LoadingWithSlowHintState extends State<LoadingWithSlowHint> {
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(AppScope.of(context).language);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ContainedLoadingIndicator(size: 56),
          const SizedBox(height: 18),
          AnimatedOpacity(
            opacity: _slow ? 1 : 0,
            duration: const Duration(milliseconds: 500),
            child: Text(
              s.slowNetwork,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown only when there is nothing at all to display — no network and no
/// saved copy. Anything cached is always shown instead of this.
class ConnectionErrorView extends StatelessWidget {
  const ConnectionErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(AppScope.of(context).language);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(Icons.wifi_off_rounded,
                  size: 36, color: scheme.onSecondaryContainer),
            ),
            const SizedBox(height: 18),
            Text(
              s.noConnection,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              s.noConnectionSub,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(s.retry),
            ),
          ],
        ),
      ),
    );
  }
}
