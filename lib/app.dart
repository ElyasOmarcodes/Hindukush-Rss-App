import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/config/feeds.dart';
import 'core/theme/app_theme.dart';
import 'state/app_state.dart';
import 'ui/splash/splash_screen.dart';

class HindukushApp extends StatelessWidget {
  const HindukushApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: appState,
      child: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          return MaterialApp(
            title: 'هندوکش غږ',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(appState.seedColor),
            darkTheme: AppTheme.dark(appState.seedColor),
            themeMode: appState.themeMode,
            locale: appState.locale,
            supportedLocales: const [
              Locale('ps'),
              Locale('fa'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // Pashto ('ps') has no bundled MaterialLocalizations; fall back to
            // Farsi/Arabic so RTL widgets still get sensible localizations.
            localeResolutionCallback: (locale, supported) {
              final lang = appState.language;
              if (lang == AppLanguage.english) return const Locale('en');
              return const Locale('fa');
            },
            builder: (context, child) {
              // Force the correct text direction for the chosen language.
              return Directionality(
                textDirection: appState.textDirection,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
