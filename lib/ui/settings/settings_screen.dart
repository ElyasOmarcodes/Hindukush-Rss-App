import 'package:flutter/material.dart';

import '../../core/config/feeds.dart';
import '../../core/localization/strings.dart';
import '../../state/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lang = app.language;
    final s = S.of(lang);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
          SliverList.list(children: [
            _sectionTitle(theme, s.language),
            _LanguagePicker(app: app),
            const SizedBox(height: 8),

            _sectionTitle(theme, s.appearance),
            _ThemePicker(app: app, s: s),
            const SizedBox(height: 8),

            _sectionTitle(theme, s.offlineDb),
            _card(
              scheme,
              child: SwitchListTile(
                value: app.keepOffline,
                onChanged: app.setKeepOffline,
                title: Text(s.offlineDb),
                secondary: const Icon(Icons.sd_storage_outlined),
              ),
            ),

            _sectionTitle(theme, s.autoDeleteNews),
            _DaysPicker(
              current: app.autoDeleteNewsDays,
              options: const [0, 7, 14, 30],
              s: s,
              onChanged: app.setAutoDeleteNewsDays,
              icon: Icons.auto_delete_outlined,
            ),

            _sectionTitle(theme, s.autoDeleteRead),
            _DaysPicker(
              current: app.autoDeleteReadDays,
              options: const [0, 1, 3, 7],
              s: s,
              onChanged: app.setAutoDeleteReadDays,
              icon: Icons.mark_email_read_outlined,
            ),

            const SizedBox(height: 12),
            _card(
              scheme,
              child: ListTile(
                leading: const Icon(Icons.storage_rounded),
                title: Text(s.storedCount),
                trailing: Text(
                  s.items(app.storedCount),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            _card(
              scheme,
              child: ListTile(
                leading: Icon(Icons.delete_sweep_outlined,
                    color: scheme.error),
                title: Text(s.clearCache,
                    style: TextStyle(color: scheme.error)),
                onTap: () async {
                  await app.clearDatabase();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(s.cleared)));
                  }
                },
              ),
            ),
            const SizedBox(height: 110),
          ]),
        ],
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _card(ColorScheme scheme, {required Widget child}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Material(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      );
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final l in AppLanguage.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _PreviewChip(
                  selected: app.language == l,
                  onTap: () => app.setLanguage(l),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l.nativeName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: app.language == l
                              ? scheme.onPrimaryContainer
                              : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.code.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      _miniPreview(brightness),
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

  Widget _miniPreview(Brightness? brightness) {
    // A tiny mock of the app surface in the given brightness.
    final b = brightness ?? WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final bg = b == Brightness.dark ? const Color(0xFF141218) : const Color(0xFFFEF7FF);
    final fg = b == Brightness.dark ? const Color(0xFFCAC4D0) : const Color(0xFF49454F);
    return Container(
      width: 54,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x33000000)),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 30, height: 5, decoration: BoxDecoration(color: const Color(0xFF6750A4), borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 4),
          Container(width: 42, height: 4, decoration: BoxDecoration(color: fg, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 3),
          Container(width: 24, height: 4, decoration: BoxDecoration(color: fg, borderRadius: BorderRadius.circular(3))),
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
  });
  final Widget child;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 92,
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
    required this.icon,
  });

  final int current;
  final List<int> options;
  final S s;
  final ValueChanged<int> onChanged;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final d in options)
            ChoiceChip(
              avatar: current == d ? null : Icon(icon, size: 16),
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
