import 'package:flutter/material.dart';
import '../models/analysis_result.dart';
import '../widgets/traffic_light_widget.dart';
import '../widgets/disclaimer_widget.dart';
import '../widgets/confidence_bar.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final result =
        ModalRoute.of(context)!.settings.arguments as AnalysisResult;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado del Análisis'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Traffic light
            Center(child: TrafficLightWidget(nivel: result.status)),
            const SizedBox(height: 24),

            // Status label
            Center(
              child: Text(
                result.status.label,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(result.status),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Confidence bar
            if (result.confidence != null) ...[
              ConfidenceBar(confidence: result.confidence!),
              const SizedBox(height: 24),
            ],

            // Observations
            _SectionCard(
              title: 'Observaciones',
              content: result.observations,
              icon: Icons.visibility,
              color: const Color(0xFF6C63FF),
            ),
            const SizedBox(height: 16),

            // Recommendations
            _SectionCard(
              title: 'Recomendaciones',
              content: result.recommendations,
              icon: Icons.lightbulb,
              color: Colors.amber[700]!,
            ),
            const SizedBox(height: 16),

            // Audio analysis card (purple)
            if (result.hasCryAnalysis) ...[
              _AudioAnalysisCard(result: result),
              const SizedBox(height: 16),
            ],

            // Disclaimer
            const DisclaimerWidget(compact: true),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/home'),
                    icon: const Icon(Icons.home),
                    label: const Text('Inicio'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/camera'),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Nuevo Análisis'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(NivelUrgencia nivel) {
    switch (nivel) {
      case NivelUrgencia.normal:
        return Colors.green;
      case NivelUrgencia.requiereAtencion:
        return Colors.orange;
      case NivelUrgencia.urgente:
        return Colors.red;
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  const _SectionCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioAnalysisCard extends StatelessWidget {
  final AnalysisResult result;

  const _AudioAnalysisCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: const Color(0xFF9C27B0).withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFF9C27B0).withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.music_note, color: Color(0xFF9C27B0), size: 20),
                SizedBox(width: 8),
                Text(
                  'Análisis de Llanto',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9C27B0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow('Categoría', result.cryLabel ?? 'No clasificado'),
            if (result.cryConfidence != null)
              _InfoRow(
                'Confianza',
                '${(result.cryConfidence! * 100).toStringAsFixed(0)}%',
              ),
            if (result.cryRecommendation != null) ...[
              const SizedBox(height: 8),
              Text(
                result.cryRecommendation!,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
