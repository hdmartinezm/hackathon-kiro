import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/splash_viewmodel.dart';
import '../widgets/babyhealth_logo_widget.dart';
import '../widgets/disclaimer_widget.dart';

/// Splash screen that displays the mandatory medical disclaimer.
///
/// The user must accept the disclaimer before proceeding to the home screen.
/// Consumes [SplashViewModel] via [Provider] and navigates to `/home`
/// once [SplashState.disclaimerAccepted] becomes `true`.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SplashViewModel>();
    final state = viewModel.state;

    // Navigate to HomeScreen once disclaimer is accepted.
    if (state.disclaimerAccepted) {
      // Use addPostFrameCallback to avoid building during the build phase.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/home');
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Unsplash image card
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 170,
                    child: Image.network(
                      'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?q=80&w=800&auto=format&fit=crop',
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6F2F7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.child_friendly_rounded,
                              size: 48,
                              color: Color(0xFF389BB0),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const BabyHealthLogoWidget(size: 80),
                ),
                const SizedBox(height: 24),
                Text(
                  'BabyHealth',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2B2826),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu bebé te habla. Nosotros te ayudamos a entenderlo.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF2B2826).withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(height: 32),
                const DisclaimerWidget(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => viewModel.acceptDisclaimer(),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text(
                      'Aceptar y continuar',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF389BB0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: const Color(0xFF389BB0).withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
