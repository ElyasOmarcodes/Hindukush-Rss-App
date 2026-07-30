import 'package:flutter/material.dart';

import '../../core/localization/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import '../navigation/root_scaffold.dart';
import '../widgets/brand_logo.dart';

/// Expressive splash: a springy morphing badge + brand name + mission line.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2400), _go);
  }

  void _go() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, a, __) => const RootScaffold(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: a,
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(AppScope.of(context).language);
    final badge = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    final text = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
    );

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: badge,
              child: RotationTransition(
                turns: Tween(begin: -0.08, end: 0.0).animate(badge),
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.rXLarge),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: BrandLogo(color: scheme.onPrimaryContainer),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: text,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(text),
                child: Column(
                  children: [
                    Text(
                      s.splashTitle,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      s.splashSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
