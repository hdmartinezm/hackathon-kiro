import 'package:flutter/material.dart';

/// Shows a modal error dialog with retry and cancel options.
///
/// Returns `true` if the user wants to retry, `false` otherwise.
Future<bool> showNetworkErrorDialog({
  required BuildContext context,
  required Exception error,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error de conexión'),
          content: Text(error.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ) ??
      false;
}
