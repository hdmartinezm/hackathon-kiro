import 'package:flutter/material.dart';
import '../config/app_config.dart';

/// Widget reutilizable de disclaimer con modo compacto.
class DisclaimerWidget extends StatelessWidget {
  final bool compact;

  const DisclaimerWidget({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.amber[700], size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppConfig.disclaimer,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.amber[700], size: 32),
          const SizedBox(height: 8),
          const Text(
            'Aviso Importante',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppConfig.disclaimer,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
