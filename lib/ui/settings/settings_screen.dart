import 'package:flutter/material.dart';

import '../../core/config/feeds.dart';
import '../../core/localization/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import '../about/about_screen.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/edge_fade.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lang = app.language;
    final s = S.of(lang);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: scheme.surface,
            surfaceTintColor: Colors.transparent,
            title: Text(s.settingsTitle),
          ),
          const SliverFadeUnderAppBar(),
          SliverList.list(children: [
            // ---- General ----
            _SectionHeader(icon: Icons.tune_rounded, title: s.sectionGeneral),
            _Group(children: [
              _tileHeader(context, Icons.translate_rounded, s.language),
              _LanguagePicker(app: app),
              const SizedBox(height: 8),
            ]),

            // ---- Appearance & colour ----
            _SectionHeader(
                icon: Icons.palette_outlined, title: s.sectionAppearance),
            _Group(children: [
              _tileHeader(context, Icons.brightness_6_rounded, s.appearance),
              _ThemePicker(app: app, s: s),
              const Divider(height: 24, indent: 16, endIndent: 16),
              _tileHeader(context, Icons.color_lens_outlined, s.accentColor),
              _AccentPicker(app: app),
              const SizedBox(height: 12),
            ]),

            // ---- Notifications ----
            _SectionHeader(
                icon: Icons.notifications_outlined, title: s.notifications),
            _Group(children: [
              SwitchListTile(
                value: app.notificationsEnabled,
                onChanged: app.setNotificationsEnabled,
                title: Text(s.notifications),
                subtitle: Text(s.notificationsSub),
                secondary: const Icon(Icons.notifications_active_outlined),
              ),
            ]),

            // ---- Content & offline ----
            _SectionHeader(
                icon: Icons.sd_storage_outlined, title: s.sectionContent),
            _Group(children: [
              SwitchListTile(
                value: app.keepOffline,
                onChanged: app.setKeepOffline,
                title: Text(s.offlineDb),
                secondary: const Icon(Icons.cloud_download_outlined),
              ),
              const Divider(height: 8, indent: 16, endIndent: 16),
              _tileHeader(context, Icons.auto_delete_outlined, s.autoDeleteNews),
              _DaysPicker(
                current: app.autoDeleteNewsDays,
                options: const [0, 7, 14, 30],
                s: s,
                onChanged: app.setAutoDeleteNewsDays,
              ),
              _tileHeader(
                  context, Icons.mark_email_read_outlined, s.autoDeleteRead),
              _DaysPicker(
                current: app.autoDeleteReadDays,
                options: const [0, 1, 3, 7],
                s: s,
                onChanged: app.setAutoDeleteReadDays,
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.storage_rounded),
                title: Text(s.storedCount),
                trailing: Text(
                  s.items(app.storedCount),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                leading:
                    Icon(Icons.delete_sweep_outlined, color: scheme.error),
                title:
                    Text(s.clearCache, style: TextStyle(color: scheme.error)),
                onTap: () async {
                  final ok = await showConfirmDialog(
                    context,
                    icon: Icons.delete_sweep_outlined,
                    title: s.clearCache,
                    message: s.clearDbMsg,
                    confirmLabel: s.clearCache,
                    danger: true,
                  );
                  if (!ok) return;
                  await app.clearDatabase();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(s.cleared)));
                  }
                },
              ),
            ]),

            // ---- About (moved out of the nav bar) ----
            _SectionHeader(
                icon: Icons.info_outline_rounded, title: s.navAbout),
            _Group(children: [
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: Text(s.aboutTitle),
                subtitle: Text(s.appName),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
              ),
            ]),
            const SizedBox(height: 110),
          ]),
        ],
      ),
    );
  }

  Widget _tileHeader(BuildContext context, IconData icon, String text) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Text(text,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }
}

class _AccentPicker extends StatelessWidget {
  const _AccentPicker({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final color in AppTheme.presets)
            _Swatch(
              color: color,
              selected: app.seedColor.toARGB32() == color.toARGB32(),
              onTap: () => app.setSeedColor(color),
              ring: scheme.onSurface,
            ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
    required this.ring,
  });
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? ring : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: selected ? 10 : 0,
            ),
          ],
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
            : null,
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final l in AppLanguage.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _PreviewChip(
                  selected: app.language == l,
                  onTap: () => app.setLanguage(l),
                  height: 96,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: app.language == l
                              ? scheme.primary
                              : scheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          l.code.toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: app.language == l
                                ? scheme.onPrimary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.nativeName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: app.language == l
                              ? scheme.onPrimaryContainer
                              : scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.app, required this.s});
  final AppState app;
  final S s;

  @override
  Widget build(BuildContext context) {
    final options = [
      (ThemeMode.light, s.themeLight, Brightness.light),
      (ThemeMode.dark, s.themeDark, Brightness.dark),
      (ThemeMode.system, s.themeSystem, null),
    ];
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final (mode, label, brightness) in options)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _PreviewChip(
                  selected: app.themeMode == mode,
                  onTap: () => app.setThemeMode(mode),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ThemeMiniPreview(
                        seed: app.seedColor,
                        brightness: brightness,
                      ),
                      const SizedBox(height: 8),
                      Text(label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: app.themeMode == mode
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: scheme.onSurface,
                          )),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A realistic mini phone mock reflecting the chosen accent + brightness.
class _ThemeMiniPreview extends StatelessWidget {
  const _ThemeMiniPreview({required this.seed, required this.brightness});
  final Color seed;
  final Brightness? brightness;

  @override
  Widget build(BuildContext context) {
    final b = brightness ??
        MediaQuery.platformBrightnessOf(context);
    final s = ColorScheme.fromSeed(seedColor: seed, brightness: b);
    Widget bar(double w, Color c, [double h = 5]) => Container(
          width: w,
          height: h,
          decoration:
              BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
        );
    return Container(
      width: 62,
      height: 78,
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: s.outlineVariant),
      ),
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(30, s.primary, 8),
          const SizedBox(height: 6),
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: s.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: s.secondary, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      bar(24, s.onSurfaceVariant, 3),
                      const SizedBox(height: 2),
                      bar(16, s.onSurfaceVariant.withValues(alpha: 0.6), 3),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Center(
            child: Container(
              width: 40,
              height: 12,
              decoration: BoxDecoration(
                color: s.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({
    required this.child,
    required this.selected,
    required this.onTap,
    this.height = 118,
  });
  final Widget child;
  final bool selected;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? scheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DaysPicker extends StatelessWidget {
  const _DaysPicker({
    required this.current,
    required this.options,
    required this.s,
    required this.onChanged,
  });

  final int current;
  final List<int> options;
  final S s;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final d in options)
            ChoiceChip(
              label: Text(d == 0 ? s.never : s.days(d)),
              selected: current == d,
              onSelected: (_) => onChanged(d),
              selectedColor: scheme.secondaryContainer,
            ),
        ],
      ),
    );
  }
}
