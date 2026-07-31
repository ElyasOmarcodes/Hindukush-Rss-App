import 'package:flutter/material.dart';

/// Material 3 (Expressive-flavoured) theming. A single expressive purple seed
/// drives both light and dark schemes; shapes are deliberately rounder and
/// motion springier than the framework defaults to match the design mocks.
class AppTheme {
  static const Color seed = Color(0xFF6750A4);

  // Expressive corner radii used across custom components.
  static const double rSmall = 12;
  static const double rMedium = 20;
  static const double rLarge = 28;
  static const double rXLarge = 36;

  /// The 5 selectable primary-colour presets.
  static const List<Color> presets = [
    Color(0xFF6750A4), // Hindukush purple (default)
    Color(0xFF1466B8), // blue
    Color(0xFF2E7D5B), // green
    Color(0xFFB5651D), // amber/orange
    Color(0xFFB53063), // magenta
  ];

  static ThemeData light([Color? seedColor]) =>
      _base(Brightness.light, seedColor ?? seed);
  static ThemeData dark([Color? seedColor]) =>
      _base(Brightness.dark, seedColor ?? seed);

  static ThemeData _base(Brightness brightness, Color seedColor) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      // A clearly-visible ripple on every tap.
      splashFactory: InkRipple.splashFactory,
      splashColor: scheme.primary.withValues(alpha: 0.20),
      highlightColor: scheme.primary.withValues(alpha: 0.10),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rLarge)),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        elevation: 3,
        height: 72,
        indicatorColor: scheme.secondaryContainer,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rMedium)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(rXLarge)),
        ),
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 12,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(rMedium)),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.4),
        space: 1,
        thickness: 1,
      ),
    );
  }
}
