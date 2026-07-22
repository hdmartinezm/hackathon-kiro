import 'package:flutter/material.dart';

/// Reusable confidence bar widget.
///
/// Displays a [LinearProgressIndicator] with a percentage label.
/// The [confidence] value should be between 0.0 and 1.0.
class ConfidenceBarWidget extends StatelessWidget {
  /// Confidence value between 0.0 and 1.0.
  final double confidence;

  const ConfidenceBarWidget({super.key, required this.confidence});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: confidence,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(confidence * 100).toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}
