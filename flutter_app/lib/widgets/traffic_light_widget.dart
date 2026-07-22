import 'package:flutter/material.dart';
import '../models/analysis_result.dart';

/// Widget de semáforo (verde/amarillo/rojo) basado en NivelUrgencia.
class TrafficLightWidget extends StatelessWidget {
  final NivelUrgencia nivel;

  const TrafficLightWidget({super.key, required this.nivel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(40),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Light(
            color: Colors.red,
            isActive: nivel == NivelUrgencia.urgente,
          ),
          const SizedBox(height: 8),
          _Light(
            color: Colors.orange,
            isActive: nivel == NivelUrgencia.requiereAtencion,
          ),
          const SizedBox(height: 8),
          _Light(
            color: Colors.green,
            isActive: nivel == NivelUrgencia.normal,
          ),
        ],
      ),
    );
  }
}

class _Light extends StatelessWidget {
  final Color color;
  final bool isActive;

  const _Light({required this.color, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? color : color.withOpacity(0.2),
        boxShadow: isActive
            ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 12)]
            : null,
      ),
    );
  }
}
