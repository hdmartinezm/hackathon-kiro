import 'package:flutter/material.dart';
import '../models/audio_result.dart';
import '../widgets/confidence_bar.dart';
import '../widgets/disclaimer_widget.dart';

class AudioResultScreen extends StatelessWidget {
  const AudioResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final result =
        ModalRoute.of(context)!.settings.arguments as AudioResult;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado de Audio'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF9C27B0).withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.music_note,
                  size: 64,
                  color: Color(0xFF9C27B0),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Category label
            Center(
              child: Text(
                result.label,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9C27B0),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Categoría: ${result.category}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Confidence
            ConfidenceBar(confidence: result.confidence),
            const SizedBox(height: 24),

            // Recommendation
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb,
                            color: Colors.amber[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Recomendación',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      result.recommendation,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

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
                        Navigator.pushReplacementNamed(context, '/audio'),
                    icon: const Icon(Icons.mic),
                    label: const Text('Nuevo Análisis'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
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
}
