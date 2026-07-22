import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/audio_screen.dart';
import 'screens/result_screen.dart';
import 'screens/audio_result_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BabyHealthApp());
}

class BabyHealthApp extends StatelessWidget {
  const BabyHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BabyHealth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/camera': (context) => const CameraScreen(),
        '/audio': (context) => const AudioScreen(),
        '/result': (context) => const ResultScreen(),
        '/audio-result': (context) => const AudioResultScreen(),
      },
    );
  }
}
