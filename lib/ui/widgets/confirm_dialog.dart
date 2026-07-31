import 'package:flutter/material.dart';

import '../../core/localization/strings.dart';
import '../../state/app_state.dart';
import 'expressive_button.dart';

/// A Material 3 dialog with a hero icon, used for critical/destructive actions.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  required String confirmLabel,
  bool danger = false,
}) async {
  final s = S.of(AppScope.of(context).language);
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(icon, size: 28),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(message, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(s.cancel),
        ),
        ExpressiveButton(
          color: danger ? scheme.error : scheme.primary,
          foreground: danger ? scheme.onError : scheme.onPrimary,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
