import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/disclaimer_widget.dart';

/// Home screen that displays the medical disclaimer and capture options.
///
/// Consumes [HomeViewModel] via [Provider]. Provides buttons to record or
/// select a video directly (no intermediate navigation). Shows a preview
/// placeholder when media is captured, and navigates to `/analysis` once
/// capture completes.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final state = viewModel.state;

    // Navigate to ModelSelectorScreen when capture is complete.
    if (state.captureStatus == 'captured' && state.media != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamed(
          '/model-selector',
          arguments: state.media!,
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('BabyHealth'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final authViewModel = context.read<AuthViewModel>();
              await authViewModel.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/web-landing');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome banner with Unsplash image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 150,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        'https://images.unsplash.com/photo-1544126592-807ade215a0b?q=80&w=800&auto=format&fit=crop',
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: const Color(0xFFD6F2F7),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF389BB0),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFD6F2F7),
                            child: const Center(
                              child: Icon(
                                Icons.face_rounded,
                                size: 48,
                                color: Color(0xFF389BB0),
                              ),
                            ),
                          );
                        },
                      ),
                      // Gradient overlay for text readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.black.withValues(alpha: 0.55),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Welcome message
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Text(
                          '¿Cómo está tu bebé hoy?',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const DisclaimerWidget(compact: true),
              ),
              const SizedBox(height: 32),
              // Title
              Center(
                child: Text(
                  'Analizar bebé',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2B2826),
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Grabe o seleccione un video corto de su bebé para '
                  'obtener una orientación preliminar sobre su estado de salud.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF2B2826).withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                ),
              ),
              const SizedBox(height: 24),
              // Capture card area
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E0DA)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Video preview area (visible when captured)
                    if (state.captureStatus == 'captured' && state.media != null)
                      _buildPreviewPlaceholder(context, state.media!.fileName),
                    if (state.captureStatus == 'captured' && state.media != null)
                      const SizedBox(height: 20),
                    // Error message
                    if (state.captureStatus == 'error' &&
                        state.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.errorMessage!,
                                style: TextStyle(
                                    color: Colors.red[800], fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Loading indicator
                    if (state.captureStatus == 'recording')
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text(
                              'Grabando video...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: state.captureStatus == 'idle' ||
                                state.captureStatus == 'error'
                            ? () => viewModel.recordVideo()
                            : null,
                        icon: const Icon(Icons.videocam_rounded),
                        label: const Text(
                          'Grabar Video',
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
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: state.captureStatus == 'idle' ||
                                state.captureStatus == 'error'
                            ? () => viewModel.pickVideo()
                            : null,
                        icon: const Icon(Icons.folder_open_rounded),
                        label: const Text(
                          'Seleccionar Video',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE87055),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    // Reset button (visible when captured)
                    if (state.captureStatus == 'captured') ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 52,
                        child: TextButton.icon(
                          onPressed: () => viewModel.resetCapture(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text(
                            'Reiniciar',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewPlaceholder(BuildContext context, String fileName) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFD6F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_file_rounded,
                size: 48, color: const Color(0xFF389BB0)),
            const SizedBox(height: 8),
            Text(
              'Video listo',
              style: TextStyle(
                color: const Color(0xFF389BB0),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              fileName,
              style: const TextStyle(
                  color: Color(0xFF2B2826), fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
