import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_localizations.dart';
import '../core/app_settings.dart';

/// Compact theme (light/dark) toggle + language (ES/EN) selector.
///
/// Reads and updates [AppSettings]; changes are persisted and applied
/// app-wide immediately.
class SettingsControls extends StatelessWidget {
  /// When true uses a lighter foreground suitable for dark/transparent bars.
  final Color? foreground;

  const SettingsControls({super.key, this.foreground});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final fg = foreground ?? Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Theme toggle
        IconButton(
          tooltip: settings.isDark ? context.l10n.lightMode : context.l10n.darkMode,
          onPressed: () => context.read<AppSettings>().toggleTheme(),
          icon: Icon(
            settings.isDark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            color: fg,
            size: 20,
          ),
        ),
        // Language selector
        PopupMenuButton<String>(
          tooltip: context.l10n.language,
          onSelected: (value) {
            context.read<AppSettings>().setLocale(Locale(value));
          },
          itemBuilder: (context) => [
            _langItem(context, 'es', context.l10n.spanish, settings.languageCode == 'es'),
            _langItem(context, 'en', context.l10n.english, settings.languageCode == 'en'),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language_rounded, color: fg, size: 20),
              const SizedBox(width: 4),
              Text(
                settings.languageCode.toUpperCase(),
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Icon(Icons.arrow_drop_down_rounded, color: fg, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _langItem(
    BuildContext context,
    String code,
    String label,
    bool selected,
  ) {
    return PopupMenuItem<String>(
      value: code,
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_rounded : Icons.language_rounded,
            size: 18,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }
}
