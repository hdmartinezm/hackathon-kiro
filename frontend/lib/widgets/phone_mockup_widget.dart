import 'package:flutter/material.dart';

import '../models/analysis_config.dart';
import '../models/captured_media.dart';
import '../views/analysis_screen.dart';
import '../views/model_selector_screen.dart';

/// A visual phone mockup frame that wraps a child widget in an isolated
/// [Navigator].
///
/// Renders an elegant smartphone outline with a dark border, rounded corners,
/// a top notch/camera cutout, an iOS-style status bar, and a deep shadow.
/// The [child] is rendered inside an internal [Navigator] so that navigation
/// (e.g. HomeScreen → AnalysisScreen) occurs exclusively within the phone
/// frame, leaving the surrounding web landing page unaffected.
///
/// Internal routes:
/// - `/` or `/home` → [child] (typically [HomeScreen])
/// - `/analysis` → [AnalysisScreen] (receives [CapturedMedia] as arguments)
class PhoneMockupWidget extends StatelessWidget {
  /// The widget to display as the home route inside the phone screen.
  final Widget child;

  /// Width of the phone mockup. Defaults to 280.
  final double width;

  /// Height of the phone mockup. Defaults to 560.
  final double height;

  const PhoneMockupWidget({
    super.key,
    required this.child,
    this.width = 280,
    this.height = 560,
  });

  @override
  Widget build(BuildContext context) {
    final navigatorKey = GlobalKey<NavigatorState>();
    final double notchWidth = width * 0.35;
    const double notchHeight = 24;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Screen content with internal Navigator
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              width: width - 24,
              height: height - 24,
              child: Column(
                children: [
                  _StatusBar(),
                  // App content with isolated Navigator
                  Expanded(
                    child: Navigator(
                      key: navigatorKey,
                      onGenerateRoute: (settings) {
                        switch (settings.name) {
                          case '/model-selector':
                            final media =
                                settings.arguments as CapturedMedia;
                            return MaterialPageRoute(
                              builder: (_) => ModelSelectorScreen(media: media),
                            );
                          case '/analysis':
                            final config =
                                settings.arguments as AnalysisConfig;
                            return MaterialPageRoute(
                              builder: (_) => AnalysisScreen(config: config),
                            );
                          case '/home':
                            return MaterialPageRoute(
                              builder: (_) => child,
                            );
                          default:
                            return MaterialPageRoute(
                              builder: (_) => child,
                            );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Top notch / camera cutout
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: notchWidth,
                height: notchHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D2D44),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 40,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D44),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// iOS-style status bar with time, signal, and battery indicators.
class _StatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      color: const Color(0xFFFAF7F4),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Row(
        children: [
          Icon(Icons.signal_cellular_alt, size: 14, color: Color(0xFF2B2826)),
          SizedBox(width: 4),
          Icon(Icons.wifi, size: 14, color: Color(0xFF2B2826)),
          Spacer(),
          Text(
            '9:41',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2B2826),
            ),
          ),
          Spacer(),
          Icon(Icons.battery_full, size: 16, color: Color(0xFF2B2826)),
        ],
      ),
    );
  }
}
