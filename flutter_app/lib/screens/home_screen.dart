import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/auth_service.dart';

/// Home screen presenting the two main analysis options:
/// - Análisis Visual (foto) → navigates to CameraScreen
/// - Análisis de Audio → navigates to AudioScreen
///
/// Includes a footer with the medical disclaimer as required by Requirement 9.2.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final authService = AuthService();
    await authService.signOut();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Main content: analysis options
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Qué deseas analizar?',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Visual Analysis option
                    _AnalysisOptionCard(
                      icon: Icons.camera_alt,
                      title: 'Análisis Visual',
                      subtitle: 'Toma una foto de tu bebé para detectar posibles condiciones',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pushNamed(context, '/camera');
                      },
                    ),
                    const SizedBox(height: 20),
                    // Audio Analysis option
                    _AnalysisOptionCard(
                      icon: Icons.mic,
                      title: 'Análisis de Audio',
                      subtitle: 'Graba el llanto de tu bebé para identificar su causa',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pushNamed(context, '/audio');
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Footer with medical disclaimer
            const _DisclaimerFooter(),
          ],
        ),
      ),
    );
  }
}

/// Card widget for each analysis option with icon, title, and subtitle.
class _AnalysisOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AnalysisOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Footer widget displaying the medical disclaimer.
class _DisclaimerFooter extends StatelessWidget {
  const _DisclaimerFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Text(
        AppConfig.disclaimerMedico,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 11,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
