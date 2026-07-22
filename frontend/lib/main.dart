import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_config.dart';
import 'models/analysis_config.dart';
import 'models/captured_media.dart';
import 'repositories/analysis_repository.dart';
import 'repositories/capture_repository.dart';
import 'repositories/upload_repository.dart';
import 'services/http_client.dart';
import 'services/platform_service.dart';
import 'services/storage_service.dart';
import 'services/video_capture_service.dart';
import 'viewmodels/analysis_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/splash_viewmodel.dart';
import 'views/analysis_screen.dart';
import 'views/home_screen.dart';
import 'views/model_selector_screen.dart';
import 'views/splash_screen.dart';
import 'views/web_landing_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // -- Core services --
        Provider<PlatformService>(create: (_) => PlatformService()),
        Provider<HttpClient>(
          create: (_) => HttpClient(baseUrl: ApiConfig.baseUrl),
        ),
        Provider<StorageService>(create: (_) => StorageService()),

        // -- Video capture service --
        ProxyProvider<PlatformService, VideoCaptureService>(
          update: (_, platformService, previous) =>
              previous ??
              ImagePickerVideoCaptureService(
            platformService: platformService,
          ),
        ),

        // -- Repositories --
        ProxyProvider<VideoCaptureService, CaptureRepository>(
          update: (_, service, previous) =>
              previous ??
              CaptureRepository(videoCaptureService: service),
        ),
        ProxyProvider2<HttpClient, StorageService, UploadRepository>(
          update: (_, httpClient, storageService, previous) =>
              previous ??
              UploadRepository(
            httpClient: httpClient,
            storageService: storageService,
          ),
        ),
        ProxyProvider<HttpClient, AnalysisRepository>(
          update: (_, httpClient, previous) =>
              previous ??
              AnalysisRepository(httpClient: httpClient),
        ),

        // -- ViewModels --
        ChangeNotifierProvider<SplashViewModel>(
          create: (_) => SplashViewModel(),
        ),
        ChangeNotifierProvider<HomeViewModel>(
          create: (context) => HomeViewModel(
            captureRepository:
                context.read<CaptureRepository>(),
          ),
        ),
        ChangeNotifierProvider<AnalysisViewModel>(
          create: (context) => AnalysisViewModel(
            uploadRepository:
                context.read<UploadRepository>(),
            analysisRepository:
                context.read<AnalysisRepository>(),
          ),
        ),
      ],
      child: const BabyHealthApp(),
    ),
  );
}

class BabyHealthApp extends StatelessWidget {
  const BabyHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BabyHealth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAF7F4),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF389BB0),
          primaryContainer: Color(0xFFD6F2F7),
          secondary: Color(0xFFE87055),
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF2B2826),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Color(0xFF2B2826),
          centerTitle: true,
        ),
      ),
      // Adaptive routing: Web shows landing page, native shows splash flow.
      initialRoute: kIsWeb ? '/web-landing' : '/splash',
      routes: {
        if (kIsWeb) '/web-landing': (_) => const WebLandingScreen(),
        '/splash': (_) => const SplashScreen(),
        '/home': (_) => const HomeScreen(),
        '/model-selector': (ctx) => ModelSelectorScreen(
              media: ModalRoute.of(ctx)!.settings.arguments as CapturedMedia,
            ),
        '/analysis': (ctx) => AnalysisScreen(
              config: ModalRoute.of(ctx)!.settings.arguments as AnalysisConfig,
            ),
      },
    );
  }
}
