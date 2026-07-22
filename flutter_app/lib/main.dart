import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'screens/audio_result_screen.dart';
import 'screens/audio_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/result_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/verify_email_screen.dart';

void main() {
  runApp(const BabyHealthApp());
}

/// Root widget for the BabyHealth application.
///
/// Configures MaterialApp with named routes for the full navigation flow:
/// Splash (disclaimer) → Login/Signup → Home → [Cámara | Audio] → Resultado
class BabyHealthApp extends StatelessWidget {
  const BabyHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/verify-email': (context) => const VerifyEmailScreen(),
        '/home': (context) => const HomeScreen(),
        '/camera': (context) => const CameraScreen(),
        '/audio': (context) => const AudioScreen(),
        '/result': (context) => const ResultScreen(),
        '/audio-result': (context) => const AudioResultScreen(),
      },
    );
  }
}
