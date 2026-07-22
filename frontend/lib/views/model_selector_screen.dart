import 'package:flutter/material.dart';

import '../models/analysis_config.dart';
import '../models/analysis_provider.dart';
import '../models/captured_media.dart';

/// Screen for selecting the AI model to use for analysis.
///
/// Displays two options: Bedrock (Claude) and Gemini, with descriptions
/// of each provider's capabilities. Navigates to `/analysis` with the
/// selected [AnalysisConfig].
class ModelSelectorScreen extends StatefulWidget {
  /// The captured media to analyze.
  final CapturedMedia media;

  const ModelSelectorScreen({super.key, required this.media});

  @override
  State<ModelSelectorScreen> createState() => _ModelSelectorScreenState();
}

class _ModelSelectorScreenState extends State<ModelSelectorScreen> {
  AnalysisProvider _selectedProvider = AnalysisProvider.gemini;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Modelo'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Elige el modelo de IA',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2B2826),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona qué modelo de inteligencia artificial analizará el video de tu bebé.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF2B2826).withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Provider cards
              Expanded(
                child: Column(
                  children: [
                    _buildProviderCard(
                      context,
                      provider: AnalysisProvider.gemini,
                      icon: Icons.auto_awesome_rounded,
                      color: const Color(0xFF4285F4),
                      features: [
                        'Análisis nativo de video completo',
                        'Clasificación de llanto por tipo',
                        'Detección de audio integrada',
                      ],
                      recommended: true,
                    ),
                    const SizedBox(height: 16),
                    _buildProviderCard(
                      context,
                      provider: AnalysisProvider.bedrock,
                      icon: Icons.cloud_rounded,
                      color: const Color(0xFFFF9900),
                      features: [
                        'Análisis visual por frames',
                        'Modelo Claude Sonnet',
                        'Extracción de espectrograma',
                      ],
                      recommended: false,
                    ),
                  ],
                ),
              ),

              // Continue button
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _onContinue,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text(
                    'Iniciar Análisis',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF389BB0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard(
    BuildContext context, {
    required AnalysisProvider provider,
    required IconData icon,
    required Color color,
    required List<String> features,
    required bool recommended,
  }) {
    final isSelected = _selectedProvider == provider;

    return GestureDetector(
      onTap: () => setState(() => _selectedProvider = provider),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE5E0DA),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            provider.displayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (recommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Recomendado',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        provider.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  const Color(0xFF2B2826).withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                Radio<AnalysisProvider>(
                  value: provider,
                  groupValue: _selectedProvider,
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedProvider = value);
                  },
                  activeColor: color,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: isSelected
                          ? color
                          : const Color(0xFF2B2826).withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF2B2826)
                                  .withValues(alpha: isSelected ? 0.8 : 0.5),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onContinue() {
    final config = AnalysisConfig(
      media: widget.media,
      provider: _selectedProvider,
    );
    Navigator.of(context).pushReplacementNamed(
      '/analysis',
      arguments: config,
    );
  }
}
