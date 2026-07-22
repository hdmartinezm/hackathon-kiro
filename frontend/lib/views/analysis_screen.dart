import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/analysis_result.dart';
import '../models/captured_media.dart';
import '../viewmodels/analysis_viewmodel.dart';
import '../viewmodels/states/analysis_state.dart';
import '../widgets/confidence_bar_widget.dart';
import '../widgets/disclaimer_widget.dart';
import '../widgets/error_dialog_widget.dart';
import '../widgets/traffic_light_widget.dart';

/// Analysis screen that displays the results of the neonatal analysis.
///
/// Consumes [AnalysisViewModel] via [Provider]. Receives [CapturedMedia] via
/// route arguments and triggers the analysis flow on init. Shows loading,
/// error dialog, or the complete result with traffic light, observations,
/// recommendations, and optional fields.
class AnalysisScreen extends StatefulWidget {
  /// The captured media to analyze.
  final CapturedMedia media;

  const AnalysisScreen({super.key, required this.media});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool _analysisStarted = false;
  bool _errorDialogShown = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AnalysisViewModel>();
    final state = viewModel.state;

    // Start analysis on first build.
    if (!_analysisStarted) {
      _analysisStarted = true;
      _errorDialogShown = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        viewModel.startAnalysis(widget.media);
      });
    }

    // Show error dialog once when status is 'error'.
    if (state.status == 'error' && !_errorDialogShown) {
      _errorDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final shouldRetry = await showNetworkErrorDialog(
          context: context,
          error: Exception(state.errorMessage ?? 'Ocurrió un error inesperado.'),
        );
        if (shouldRetry) {
          viewModel.reset();
          _analysisStarted = false;
          _errorDialogShown = false;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado del Análisis'),
      ),
      body: SafeArea(
        child: _buildBody(context, viewModel, state),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AnalysisViewModel viewModel,
    AnalysisState state,
  ) {
    switch (state.status) {
      case 'uploading':
      case 'analyzing':
        return _buildLoading(state.status);
      case 'error':
        // Return empty container; the dialog is shown via postFrameCallback.
        return const SizedBox.shrink();
      case 'completed':
        if (state.result != null) {
          return _buildResult(context, viewModel, state.result!);
        }
        return const SizedBox.shrink();
      default:
        return _buildLoading('idle');
    }
  }

  Widget _buildLoading(String status) {
    final message = status == 'uploading'
        ? 'Subiendo video...'
        : status == 'analyzing'
            ? 'Analizando video...'
            : 'Preparando...';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(
    BuildContext context,
    AnalysisViewModel viewModel,
    AnalysisResult result,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Traffic light indicator
          TrafficLightWidget(status: result.status),
          const SizedBox(height: 24),
          // Observations
          _buildSection(
            context,
            title: 'Observaciones',
            icon: Icons.description_outlined,
            child: Text(
              result.observations,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          // Recommendations
          _buildSection(
            context,
            title: 'Recomendaciones',
            icon: Icons.lightbulb_outline,
            child: Text(
              result.recommendations,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
            ),
          ),
          // Optional: Confidence
          if (result.confidence != null) ...[
            const SizedBox(height: 16),
            _buildSection(
              context,
              title: 'Nivel de Confianza',
              icon: Icons.speed_rounded,
              child: ConfidenceBarWidget(confidence: result.confidence!),
            ),
          ],
          // Optional: Cry category
          if (result.cryCategory != null) ...[
            const SizedBox(height: 16),
            _buildSection(
              context,
              title: 'Categoría de Llanto',
              icon: Icons.hearing_rounded,
              child: Text(
                result.cryCategory!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
          // Optional: Degradation warning
          if (result.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange[800], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.error!,
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          // Medical disclaimer
          DisclaimerWidget(
            compact: true,
            text: result.disclaimer,
          ),
          const SizedBox(height: 24),
          // Reset button
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                viewModel.reset();
                _navigateHome(context);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'Reiniciar',
                style: TextStyle(fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF389BB0),
                side: const BorderSide(color: Color(0xFF389BB0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E0DA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  void _navigateHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }
}
