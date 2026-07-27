import 'package:flutter/material.dart';

import '../core/app_localizations.dart';

/// Reusable medical disclaimer widget.
///
/// Shows a warning banner with medical disclaimer text.
/// Use [compact] mode for footer-style disclaimers (smaller text, no title).
class DisclaimerWidget extends StatelessWidget {
  /// Whether to show the compact (footer) version.
  final bool compact;

  /// Optional custom disclaimer text. Uses default text if null.
  final String? text;

  const DisclaimerWidget({super.key, this.compact = false, this.text});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }
    return _buildFull(context);
  }

  Widget _buildFull(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber[800],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.importantNotice,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text ?? context.l10n.fullDisclaimer,
            textAlign: TextAlign.justify,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.brown[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.amber[800], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text ?? context.l10n.compactDisclaimer,
              style: TextStyle(
                color: Colors.brown[700],
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
