import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../core/app_localizations.dart';
import '../core/app_settings.dart';
import '../models/analysis_config.dart';
import '../models/analysis_result.dart';
import '../models/analysis_status.dart';
import '../repositories/upload_repository.dart';
import '../services/pdf_report_service.dart';
import '../services/profile_service.dart';
import '../viewmodels/analysis_viewmodel.dart';
import '../viewmodels/states/analysis_state.dart';
import '../widgets/confidence_bar_widget.dart';
import '../widgets/disclaimer_widget.dart';
import '../widgets/error_dialog_widget.dart';
import '../widgets/traffic_light_widget.dart';

/// Analysis screen that displays the results of the neonatal analysis.
///
/// Consumes [AnalysisViewModel] via [Provider]. Receives [AnalysisConfig] via
/// route arguments containing both the media and selected provider.
/// Triggers the analysis flow on init. Shows loading, error dialog, or the
/// complete result with traffic light, observations, recommendations,
/// and optional fields including cry analysis for Gemini.
class AnalysisScreen extends StatefulWidget {
  /// Configuration containing media and selected AI provider.
  final AnalysisConfig config;

  const AnalysisScreen({super.key, required this.config});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool _analysisStarted = false;
  bool _errorDialogShown = false;
  bool _isGeneratingPdf = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AnalysisViewModel>();
    final state = viewModel.state;

    // Start analysis on first build.
    if (!_analysisStarted) {
      _analysisStarted = true;
      _errorDialogShown = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final profile = context.read<ProfileService>().profile;
        final language = context.read<AppSettings>().languageCode;
        viewModel.startAnalysis(
          widget.config.media,
          provider: widget.config.provider,
          profile: profile,
          language: language,
        );
      });
    }

    // Show error dialog once when status is 'error'.
    if (state.status == 'error' && !_errorDialogShown) {
      _errorDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final shouldRetry = await showNetworkErrorDialog(
          context: context,
          error: Exception(state.errorMessage ?? context.l10n.unexpectedErrorOccurred),
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
        title: Text(context.l10n.analysisResult),
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
        return _buildLoading(context, state.status);
      case 'error':
        // Return empty container; the dialog is shown via postFrameCallback.
        return const SizedBox.shrink();
      case 'completed':
        if (state.result != null) {
          return _buildResult(context, viewModel, state.result!);
        }
        return const SizedBox.shrink();
      default:
        return _buildLoading(context, 'idle');
    }
  }

  Widget _buildLoading(BuildContext context, String status) {
    final l10n = context.l10n;
    final message = status == 'uploading'
        ? l10n.uploadingVideo
        : status == 'analyzing'
            ? l10n.analyzingVideo
            : l10n.preparing;

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
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF2A2A28);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Traffic light indicator
          TrafficLightWidget(status: result.status),
          // WhatsApp contact button for urgent/attention statuses
          if (result.status == AnalysisStatus.requiereAtencion || result.status == AnalysisStatus.urgente) ...[
            const SizedBox(height: 16),
            _buildWhatsAppButton(context, result),
          ],
          const SizedBox(height: 24),
          // Observations
          _buildSection(
            context,
            title: l10n.observations,
            icon: Icons.description_outlined,
            child: Text(
              result.observations,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: textColor.withValues(alpha: 0.87),
                  ),
            ),
          ),
          const SizedBox(height: 16),
          // Recommendations
          _buildSection(
            context,
            title: l10n.recommendations,
            icon: Icons.lightbulb_outline,
            child: Text(
              result.recommendations,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: textColor.withValues(alpha: 0.87),
                  ),
            ),
          ),
          // Optional: Confidence
          if (result.confidence != null) ...[
            const SizedBox(height: 16),
            _buildSection(
              context,
              title: l10n.confidenceLevel,
              icon: Icons.speed_rounded,
              child: ConfidenceBarWidget(confidence: result.confidence!),
            ),
          ],
          // Optional: Cry analysis (Gemini)
          if (result.hasCryAnalysis) ...[
            const SizedBox(height: 16),
            _buildSection(
              context,
              title: l10n.cryAnalysis,
              icon: Icons.hearing_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cry label/category
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4285F4).withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          result.cryDisplayLabel ?? result.cryCategory!,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFF82B1FF) : const Color(0xFF4285F4),
                                  ),
                        ),
                      ),
                      if (result.cryConfidence != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          l10n.confidence((result.cryConfidence! * 100).toInt()),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: textColor.withValues(alpha: 0.6),
                                  ),
                        ),
                      ],
                    ],
                  ),
                  // Cry recommendation
                  if (result.cryRecommendation != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF4285F4).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.tips_and_updates_rounded,
                            size: 18,
                            color: isDark ? const Color(0xFF82B1FF) : const Color(0xFF4285F4),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              result.cryRecommendation!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    height: 1.4,
                                    color: textColor.withValues(alpha: 0.87),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          // Optional: Degradation warning
          if (result.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3D2E1F) : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.orange[700]! : Colors.orange[200]!,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: isDark ? Colors.orange[300] : Colors.orange[800], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.error!,
                      style: TextStyle(
                        color: isDark ? Colors.orange[100] : Colors.orange[900],
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
          // Medical disclaimer (always shown in the selected UI language)
          const DisclaimerWidget(compact: true),
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
              label: Text(
                l10n.reset,
                style: const TextStyle(fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4B9B9B),
                side: const BorderSide(color: Color(0xFF4B9B9B)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE8E1D9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
                      color: isDark ? Colors.white : null,
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

  Widget _buildWhatsAppButton(BuildContext context, AnalysisResult result) {
    final l10n = context.l10n;
    final profile = context.read<ProfileService>().profile;

    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: _isGeneratingPdf
            ? null
            : () => _launchWhatsAppWithReport(context, profile.pediatricianWhatsApp, result),
        icon: _isGeneratingPdf
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.chat_rounded, size: 22),
        label: Text(
          _isGeneratingPdf
              ? (l10n.isEn ? 'Generating report...' : 'Generando reporte...')
              : l10n.contactDoctorWhatsApp,
          style: const TextStyle(fontSize: 16),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF25D366), // WhatsApp green
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _launchWhatsAppWithReport(
    BuildContext context,
    String? phoneNumber,
    AnalysisResult result,
  ) async {
    final l10n = context.l10n;

    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noDoctorWhatsApp),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: l10n.profile,
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
          ),
        ),
      );
      return;
    }

    // Start generating PDF
    setState(() => _isGeneratingPdf = true);

    String? pdfDownloadUrl;
    try {
      // Generate PDF
      final profile = context.read<ProfileService>().profile;
      final isEnglish = l10n.isEn;
      final pdfBytes = await PdfReportService.generateReport(
        result: result,
        profile: profile,
        isEnglish: isEnglish,
      );

      // Upload PDF and get download URL
      final uploadRepository = context.read<UploadRepository>();
      pdfDownloadUrl = await uploadRepository.uploadPdfReport(pdfBytes);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.isEn
                  ? 'Could not generate report. Opening WhatsApp without report.'
                  : 'No se pudo generar el reporte. Abriendo WhatsApp sin reporte.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }

    // Clean the phone number (remove spaces, dashes, etc.) and remove leading +
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanNumber.startsWith('+')) {
      cleanNumber = cleanNumber.substring(1);
    }

    // Create WhatsApp message with PDF link
    String messageText;
    if (pdfDownloadUrl != null) {
      messageText = l10n.isEn
          ? 'Hello, I need a consultation about my baby. The BabyHealth app indicated that attention is needed.\n\nHere is the analysis report: $pdfDownloadUrl\n\n(Link valid for 1 hour)'
          : 'Hola, necesito una consulta sobre mi bebé. La app BabyHealth indicó que requiere atención.\n\nAquí está el reporte del análisis: $pdfDownloadUrl\n\n(Enlace válido por 1 hora)';
    } else {
      messageText = l10n.isEn
          ? 'Hello, I need a consultation about my baby. The BabyHealth app indicated that attention is needed.'
          : 'Hola, necesito una consulta sobre mi bebé. La app BabyHealth indicó que requiere atención.';
    }

    final message = Uri.encodeComponent(messageText);
    final whatsappUrlString = 'https://wa.me/$cleanNumber?text=$message';

    // On web, use window.open directly for better compatibility
    if (kIsWeb) {
      html.window.open(whatsappUrlString, '_blank');
    } else {
      final whatsappUrl = Uri.parse(whatsappUrlString);
      try {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.isEn
                    ? 'Could not open WhatsApp'
                    : 'No se pudo abrir WhatsApp',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }
}
