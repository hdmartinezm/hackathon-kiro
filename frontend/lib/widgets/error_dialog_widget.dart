import 'package:flutter/material.dart';

import '../core/app_localizations.dart';

/// Shows a modal error dialog with retry and cancel options.
///
/// Returns `true` if the user wants to retry, `false` otherwise.
Future<bool> showNetworkErrorDialog({
  required BuildContext context,
  required Exception error,
}) async {
  final l10n = context.l10n;
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.connectionErrorTitle),
          content: Text(error.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ) ??
      false;
}
