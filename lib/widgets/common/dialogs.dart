import 'package:flutter/material.dart';

import 'app_scope.dart';

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final s = context.s;
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(s.cancel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showSnack(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      persist: false,
      action: actionLabel != null && onAction != null
          ? SnackBarAction(label: actionLabel, onPressed: onAction)
          : null,
    ),
  );
}
