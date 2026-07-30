import 'package:flutter/material.dart';

import '../../../core/localization/strings.dart';
import '../../../state/app_state.dart';

/// The reading quick-settings bottom sheet: font size + line spacing (centered
/// sliders) and text alignment (a connected button group). Every change is
/// applied live to the article behind the sheet.
class QuickSettingsSheet extends StatelessWidget {
  const QuickSettingsSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const QuickSettingsSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(app.language);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              s.quickSettings,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 20),

          // Font size — centered slider
          _label(theme, s.fontSize, Icons.format_size_rounded),
          Slider(
            value: app.fontScale,
            min: 0.8,
            max: 1.8,
            divisions: 10,
            label: '${(app.fontScale * 100).round()}%',
            onChanged: app.setFontScale,
          ),
          const SizedBox(height: 8),

          // Line height — centered slider
          _label(theme, s.lineHeight, Icons.format_line_spacing_rounded),
          Slider(
            value: app.lineHeight,
            min: 1.2,
            max: 2.4,
            divisions: 12,
            label: app.lineHeight.toStringAsFixed(1),
            onChanged: app.setLineHeight,
          ),
          const SizedBox(height: 20),

          // Text alignment — connected button group
          _label(theme, s.textAlign, Icons.format_align_left_rounded),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ReadingAlign>(
              segments: [
                ButtonSegment(
                  value: ReadingAlign.start,
                  icon: const Icon(Icons.format_align_right_rounded),
                  label: Text(s.alignStart),
                ),
                ButtonSegment(
                  value: ReadingAlign.center,
                  icon: const Icon(Icons.format_align_center_rounded),
                  label: Text(s.alignCenter),
                ),
                ButtonSegment(
                  value: ReadingAlign.justify,
                  icon: const Icon(Icons.format_align_justify_rounded),
                  label: Text(s.alignJustify),
                ),
              ],
              selected: {app.readingAlign},
              onSelectionChanged: (set) => app.setReadingAlign(set.first),
              showSelectedIcon: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(ThemeData theme, String text, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(text,
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
