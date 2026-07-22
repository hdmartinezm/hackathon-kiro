import 'package:flutter/material.dart';

import '../models/analysis_status.dart';

/// Reusable traffic light widget that displays the analysis severity status.
///
/// Shows a pill/badge-style card with a pastel background, icon, and label
/// based on the given [status].
class TrafficLightWidget extends StatelessWidget {
  /// The analysis severity status to display.
  final AnalysisStatus status;

  const TrafficLightWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final bgColor = _bgColor;
    final icon = _icon;
    final label = _label;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: _color),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _color,
                ),
          ),
        ],
      ),
    );
  }

  Color get _color {
    switch (status) {
      case AnalysisStatus.normal:
        return const Color(0xFF2E7D32);
      case AnalysisStatus.requiereAtencion:
        return const Color(0xFFF57F17);
      case AnalysisStatus.urgente:
        return const Color(0xFFC62828);
    }
  }

  Color get _bgColor {
    switch (status) {
      case AnalysisStatus.normal:
        return const Color(0xFFE8F5E9);
      case AnalysisStatus.requiereAtencion:
        return const Color(0xFFFFF8E1);
      case AnalysisStatus.urgente:
        return const Color(0xFFFFEBEE);
    }
  }

  IconData get _icon {
    switch (status) {
      case AnalysisStatus.normal:
        return Icons.check_circle_rounded;
      case AnalysisStatus.requiereAtencion:
        return Icons.warning_rounded;
      case AnalysisStatus.urgente:
        return Icons.error_rounded;
    }
  }

  String get _label {
    switch (status) {
      case AnalysisStatus.normal:
        return 'Normal';
      case AnalysisStatus.requiereAtencion:
        return 'Requiere Atención';
      case AnalysisStatus.urgente:
        return 'Urgente';
    }
  }
}
