import 'package:flutter/material.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';

enum AlertKind { success, error, warning, info }

/// Shows a centered modal alert (icon + title + message + one button).
/// Use instead of SnackBars for sale confirmations and other notices.
Future<void> showAppAlert(
  BuildContext context, {
  required String message,
  String? title,
  AlertKind kind = AlertKind.info,
}) {
  final (IconData icon, Color color, String defaultTitle) = switch (kind) {
    AlertKind.success => (Icons.check_circle, AppColors.success, '¡Listo!'),
    AlertKind.error => (Icons.error_outline, AppColors.danger, 'Ups'),
    AlertKind.warning => (
        Icons.warning_amber_rounded,
        AppColors.warning,
        'Atención'
      ),
    AlertKind.info => (Icons.info_outline, AppColors.primary, 'Aviso'),
  };

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(icon, color: color, size: 44),
      title: Text(title ?? defaultTitle, textAlign: TextAlign.center),
      content: Text(message, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}
