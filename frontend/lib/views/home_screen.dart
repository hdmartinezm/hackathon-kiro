import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../core/app_localizations.dart';
import '../core/app_theme.dart';
import '../models/captured_media.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/disclaimer_widget.dart';
import '../widgets/settings_controls.dart';
import 'web_record_screen.dart';

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
        titleSpacing: 0,
        title: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => Navigator.of(context)
                .pushNamedAndRemoveUntil('/web-landing', (route) => false),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.home_rounded,
                    size: 20, color: Color(0xFF4B9B9B)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'BabyHealth',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Use LayoutBuilder to adapt actions based on available width
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              // On narrow screens (< 400px), use a compact popup menu
              if (screenWidth < 400) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SettingsControls(),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      tooltip: 'Menu',
                      onSelected: (value) async {
                        switch (value) {
                          case 'profile':
                            Navigator.of(context).pushNamed('/profile');
                            break;
                          case 'logout':
                            final authViewModel = context.read<AuthViewModel>();
                            await authViewModel.logout();
                            if (context.mounted) {
                              Navigator.of(context)
                                  .pushReplacementNamed('/web-landing');
                            }
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              const Icon(Icons.person_rounded, size: 20),
                              const SizedBox(width: 12),
                              Text(context.l10n.profile),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              const Icon(Icons.logout_rounded, size: 20),
                              const SizedBox(width: 12),
                              Text(context.l10n.logout),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
              // Normal layout for wider screens
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.person_rounded),
                    tooltip: context.l10n.profile,
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/profile'),
                  ),
                  const SettingsControls(),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded),
                    tooltip: context.l10n.logout,
                    onPressed: () async {
                      final authViewModel = context.read<AuthViewModel>();
                      await authViewModel.logout();
                      if (context.mounted) {
                        Navigator.of(context)
                            .pushReplacementNamed('/web-landing');
                      }
                    },
                  ),
                ],
              );
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
                            color: const Color(0xFFC8E8E8),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF4B9B9B),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFC8E8E8),
                            child: const Center(
                              child: Icon(
                                Icons.face_rounded,
                                size: 48,
                                color: Color(0xFF4B9B9B),
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
                          context.l10n.homeGreeting,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontFamily: AppTheme.serifFamily,
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
                  context.l10n.homeAnalyzeTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontFamily: AppTheme.serifFamily,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  context.l10n.homeAnalyzeSubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                ),
              ),
              const SizedBox(height: 24),
              // Capture card area
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
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
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 8),
                            Text(
                              context.l10n.recording,
                              style: const TextStyle(color: Colors.grey),
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
                            ? () => _handleRecord(context, viewModel)
                            : null,
                        icon: const Icon(Icons.videocam_rounded),
                        label: Text(
                          context.l10n.recordVideo,
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4B9B9B),
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
                        label: Text(
                          context.l10n.selectVideo,
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFDF7B5E),
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
                          label: Text(
                            context.l10n.reset,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),
        ),
      ),
    );
  }

  /// Handles the "Grabar Video" action.
  ///
  /// On web, opens the in-browser [WebRecordScreen] (camera + MediaRecorder)
  /// and stores the resulting media. On native platforms, delegates to the
  /// existing `image_picker` camera flow via the view model.
  Future<void> _handleRecord(
    BuildContext context,
    HomeViewModel viewModel,
  ) async {
    if (kIsWeb) {
      final media = await Navigator.of(context).push<CapturedMedia>(
        MaterialPageRoute(builder: (_) => const WebRecordScreen()),
      );
      if (media != null) {
        viewModel.setCapturedMedia(media);
      }
    } else {
      viewModel.recordVideo();
    }
  }

  Widget _buildPreviewPlaceholder(BuildContext context, String fileName) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFC8E8E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_file_rounded,
                size: 48, color: const Color(0xFF4B9B9B)),
            const SizedBox(height: 8),
            Text(
              context.l10n.videoReady,
              style: const TextStyle(
                color: Color(0xFF4B9B9B),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              fileName,
              style: const TextStyle(
                  color: Color(0xFF2A2A28), fontSize: 12),
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
