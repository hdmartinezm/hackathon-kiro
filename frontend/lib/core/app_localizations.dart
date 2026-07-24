import 'package:flutter/material.dart';

/// Error codes returned by AuthService for localization.
enum AuthErrorCode {
  loginFailed,
  verifyCodeFailed,
  noAccountWithEmail,
  incorrectCredentials,
  accountAlreadyExists,
  incorrectCode,
  codeExpired,
  passwordPolicyError,
  connectionError,
  configurationError,
  loginError,
  registerError,
  noPendingEmail,
  verifyError,
  resendError,
  unknown,
}

/// Lightweight, map-based localization for English and Spanish.
///
/// Access strings via `context.l10n.<key>`. The active language is driven by
/// [MaterialApp.locale] (which mirrors the user's [AppSettings] choice, falling
/// back to the browser language).
class AppLocalizations {
  final String languageCode;
  const AppLocalizations(this.languageCode);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations('es');
  }

  bool get isEn => languageCode == 'en';
  String _t(String es, String en) => isEn ? en : es;

  // ── Navbar ──
  String get navHowItWorks => _t('Cómo Funciona', 'How It Works');
  String get navFeatures => _t('Características', 'Features');
  String get navArchitecture => _t('Arquitectura', 'Architecture');
  String get navSecurity => _t('Seguridad', 'Security');
  String get navRequestAccess => _t('Solicitar acceso', 'Request access');

  // ── Hero ──
  String get heroTitle => _t(
        'Salud de tu bebé, guiada por IA',
        "Your baby's health, guided by AI",
      );
  String get heroTitleLine1 => _t('Tu bebé te habla.', 'Your baby speaks to you.');
  String get heroTitleLine2 => _t(
        'Nosotros te ayudamos a entenderlo.',
        'We help you understand it.',
      );
  String get heroSubtitle => _t(
        'Orientación preliminar inmediata para padres primerizos, '
            'con análisis visual y de llanto mediante inteligencia artificial.',
        'Immediate preliminary guidance for new parents, with visual and '
            'cry analysis powered by artificial intelligence.',
      );
  String get heroStart => _t('Comenzar ahora', 'Get started');
  String get heroDemo => _t('Ver demostración', 'View demo');
  String get badgeModels => _t('★ Bedrock + Gemini', '★ Bedrock + Gemini');
  String get badgeFast =>
      _t('🕒 Análisis en segundos', '🕒 Analysis in seconds');
  String get badgeMultimodal => _t('+ Multimodal', '+ Multimodal');

  // ── Section chips / titles ──
  String get chipHowItWorks => _t('CÓMO FUNCIONA', 'HOW IT WORKS');
  String get howItWorksTitlePrefix =>
      _t('De la duda a la orientación en ', 'From doubt to guidance in ');
  String get howItWorksTitleHighlight => _t('tres pasos', 'three steps');

  String get step1Title => _t('Captura', 'Capture');
  String get step1Desc => _t(
        'Graba o sube un video corto de tu bebé desde el navegador.',
        'Record or upload a short video of your baby from the browser.',
      );
  String get step2Title => _t('Analiza en AWS', 'Analyze on AWS');
  String get step2Desc => _t(
        'IA multimodal (Claude Sonnet 4.5 en Bedrock o Gemini 2.5 Flash) '
            'procesa el contenido.',
        'Multimodal AI (Claude Sonnet 4.5 on Bedrock or Gemini 2.5 Flash) '
            'processes the content.',
      );
  String get step3Title => _t('Recibe orientación', 'Get guidance');
  String get step3Desc => _t(
        'Resultados inmediatos con semáforo y recomendaciones.',
        'Immediate results with a traffic-light status and recommendations.',
      );

  String get chipFeatures => _t('CARACTERÍSTICAS', 'FEATURES');
  String get featuresTitle => _t(
        'Tecnología al servicio de la tranquilidad',
        'Technology at the service of peace of mind',
      );
  String get comingSoon => _t('PRÓXIMAMENTE', 'COMING SOON');

  String get featVisionLabel => _t('VISIÓN POR IA', 'AI VISION');
  String get featVisionTitle => _t('Análisis visual', 'Visual analysis');
  String get featVisionDesc => _t(
        'Detección de ictericia y evaluación del estado general del bebé.',
        'Jaundice detection and assessment of the baby\'s general condition.',
      );
  String get featAudioLabel => _t('AUDIO IA', 'AI AUDIO');
  String get featAudioTitle => _t('Análisis de llanto', 'Cry analysis');
  String get featAudioDesc => _t(
        'Clasificación de patrones de llanto con inteligencia artificial.',
        'Cry pattern classification with artificial intelligence.',
      );
  String get featAwsLabel => _t('AWS NATIVE', 'AWS NATIVE');
  String get featAwsTitle => _t('Infraestructura cloud', 'Cloud infrastructure');
  String get featAwsDesc => _t(
        'Serverless con S3 Pre-signed URLs y Lambda.',
        'Serverless with S3 pre-signed URLs and Lambda.',
      );
  String get featPrivacyLabel => _t('PRIVACIDAD', 'PRIVACY');
  String get featPrivacyTitle => _t('Tus datos seguros', 'Your data is safe');
  String get featPrivacyDesc => _t(
        'Sin almacenamiento permanente de imágenes ni videos.',
        'No permanent storage of images or videos.',
      );
  String get featEdgeLabel => _t('EDGE ML', 'EDGE ML');
  String get featEdgeTitle => _t('Procesamiento local', 'Local processing');
  String get featEdgeDesc => _t(
        'Detección on-device para respuestas rápidas.',
        'On-device detection for fast responses.',
      );
  String get featUxLabel => _t('UX CUIDADO', 'THOUGHTFUL UX');
  String get featUxTitle => _t('Diseño para padres', 'Designed for parents');
  String get featUxDesc => _t(
        'Interfaz optimizada para padres exhaustos.',
        'Interface optimized for exhausted parents.',
      );

  String get chipArchitecture => _t('ARQUITECTURA', 'ARCHITECTURE');
  String get architectureTitle => _t(
        'Infraestructura serverless en AWS',
        'Serverless infrastructure on AWS',
      );

  // ── Home ──
  String get homeGreeting =>
      _t('¿Cómo está tu bebé hoy?', 'How is your baby today?');
  String get homeAnalyzeTitle => _t('Analizar bebé', 'Analyze baby');
  String get homeAnalyzeSubtitle => _t(
        'Grabe o seleccione un video corto de su bebé para obtener una '
            'orientación preliminar sobre su estado de salud.',
        'Record or select a short video of your baby to get preliminary '
            'guidance about their health.',
      );
  String get recordVideo => _t('Grabar Video', 'Record Video');
  String get selectVideo => _t('Seleccionar Video', 'Select Video');
  String get reset => _t('Reiniciar', 'Reset');
  String get videoReady => _t('Video listo', 'Video ready');
  String get recording => _t('Grabando video...', 'Recording video...');
  String get logout => _t('Cerrar sesión', 'Log out');
  String get disclaimer => _t(
        'Esta aplicación proporciona orientación preliminar basada en IA y NO '
            'reemplaza la evaluación de un profesional de la salud. Consulte a '
            'un pediatra ante cualquier preocupación.',
        'This app provides AI-based preliminary guidance and does NOT replace '
            'evaluation by a health professional. Consult a pediatrician with '
            'any concern.',
      );

  // ── Auth ──
  String get continueWithGoogle => _t('Continuar con Google', 'Continue with Google');
  String get continueWithApple => _t('Continuar con Apple', 'Continue with Apple');
  String get continueWithFacebook =>
      _t('Continuar con Facebook', 'Continue with Facebook');
  String get orDivider => _t('o', 'or');
  String get tabLogin => _t('Ingresar', 'Log in');
  String get tabSignup => _t('Registrarse', 'Sign up');
  String get email => _t('Email', 'Email');
  String get password => _t('Contraseña', 'Password');
  String get confirmPassword => _t('Confirmar contraseña', 'Confirm password');
  String get signIn => _t('Iniciar sesión', 'Sign in');
  String get createAccount => _t('Crear cuenta', 'Create account');
  String get noAccountSignup =>
      _t('¿No tienes cuenta? Regístrate', "No account? Sign up");
  String get socialComingSoon => _t(
        'Este proveedor estará disponible pronto. Por ahora usa Google o tu '
            'email y contraseña.',
        'This provider will be available soon. For now use Google or your '
            'email and password.',
      );

  // ── Settings controls ──
  String get lightMode => _t('Modo claro', 'Light mode');
  String get darkMode => _t('Modo oscuro', 'Dark mode');
  String get language => _t('Idioma', 'Language');
  String get spanish => _t('Español', 'Spanish');
  String get english => _t('Inglés', 'English');

  // ── Validation ──
  String get emailRequired => _t('El email es requerido', 'Email is required');
  String get emailInvalid => _t('Ingresa un email válido', 'Enter a valid email');
  String get passwordRequired => _t('La contraseña es requerida', 'Password is required');
  String get passwordMinLength => _t('Mínimo 8 caracteres', 'Minimum 8 characters');
  String get passwordNeedsLowercase => _t('Debe contener al menos una minúscula', 'Must contain at least one lowercase letter');
  String get passwordNeedsNumber => _t('Debe contener al menos un número', 'Must contain at least one number');
  String get fieldRequired => _t('Requerido', 'Required');
  String get passwordsDoNotMatch => _t('Las contraseñas no coinciden', 'Passwords do not match');

  // ── Auth errors ──
  String get loginFailed => _t('No se pudo iniciar sesión', 'Could not sign in');
  String get verifyCodeFailed => _t('No se pudo verificar el código', 'Could not verify the code');
  String get noAccountWithEmail => _t('No existe una cuenta con este email', 'No account exists with this email');
  String get incorrectCredentials => _t('Email o contraseña incorrectos', 'Incorrect email or password');
  String get accountAlreadyExists => _t('Ya existe una cuenta con este email', 'An account already exists with this email');
  String get incorrectCode => _t('Código incorrecto. Intenta de nuevo.', 'Incorrect code. Try again.');
  String get codeExpired => _t('El código ha expirado. Solicita uno nuevo.', 'The code has expired. Request a new one.');
  String get passwordPolicyError => _t(
        'La contraseña debe tener al menos 8 caracteres, una minúscula y un número',
        'Password must have at least 8 characters, one lowercase letter and one number',
      );
  String get connectionError => _t('Error de conexión. Verifica tu internet.', 'Connection error. Check your internet.');
  String get configurationError => _t('Error de configuración. Recarga la página.', 'Configuration error. Reload the page.');
  String get loginError => _t('Error al iniciar sesión', 'Error signing in');
  String get registerError => _t('Error al registrarse', 'Error signing up');
  String get noPendingEmail => _t('No hay email pendiente de verificación', 'No pending email verification');
  String get verifyError => _t('Error al verificar código', 'Error verifying code');
  String get resendError => _t('Error al reenviar código', 'Error resending code');
  String unexpectedError(String error) => _t('Error inesperado: $error', 'Unexpected error: $error');

  /// Translates an AuthErrorCode to a localized string.
  String translateAuthError(AuthErrorCode code, [String? detail]) {
    switch (code) {
      case AuthErrorCode.loginFailed:
        return loginFailed;
      case AuthErrorCode.verifyCodeFailed:
        return verifyCodeFailed;
      case AuthErrorCode.noAccountWithEmail:
        return noAccountWithEmail;
      case AuthErrorCode.incorrectCredentials:
        return incorrectCredentials;
      case AuthErrorCode.accountAlreadyExists:
        return accountAlreadyExists;
      case AuthErrorCode.incorrectCode:
        return incorrectCode;
      case AuthErrorCode.codeExpired:
        return codeExpired;
      case AuthErrorCode.passwordPolicyError:
        return passwordPolicyError;
      case AuthErrorCode.connectionError:
        return connectionError;
      case AuthErrorCode.configurationError:
        return configurationError;
      case AuthErrorCode.loginError:
        return loginError;
      case AuthErrorCode.registerError:
        return registerError;
      case AuthErrorCode.noPendingEmail:
        return noPendingEmail;
      case AuthErrorCode.verifyError:
        return verifyError;
      case AuthErrorCode.resendError:
        return resendError;
      case AuthErrorCode.unknown:
        return detail != null ? unexpectedError(detail) : unexpectedError('');
    }
  }

  // ── Verify Email Screen ──
  String get emailVerified => _t('¡Email verificado! Inicia sesión para continuar.', 'Email verified! Sign in to continue.');
  String get codeResent => _t('Código reenviado a tu email', 'Code resent to your email');
  String get verifyYourEmail => _t('Verifica tu correo', 'Verify your email');
  String get codeSentTo => _t('Enviamos un código de 6 dígitos a:', 'We sent a 6-digit code to:');
  String get enterCode => _t('Ingresa el código de 6 dígitos', 'Enter the 6-digit code');
  String get verify => _t('Verificar', 'Verify');
  String get didNotReceiveCode => _t('¿No recibiste el código? Reenviar', "Didn't receive the code? Resend");

  // ── Error Dialog ──
  String get connectionErrorTitle => _t('Error de conexión', 'Connection error');
  String get cancel => _t('Cancelar', 'Cancel');
  String get retry => _t('Reintentar', 'Retry');

  // ── Camera / Recording ──
  String get noCameraFound => _t(
        'No se encontró ninguna cámara disponible en este dispositivo.',
        'No camera found on this device.',
      );
  String cameraAccessError(String detail) => _t(
        'No se pudo acceder a la cámara. Concede permisos de cámara y micrófono en el navegador e inténtalo de nuevo.\n\nDetalle: $detail',
        'Could not access the camera. Grant camera and microphone permissions in your browser and try again.\n\nDetail: $detail',
      );
  String recordingError(String error) => _t('Error al iniciar la grabación: $error', 'Error starting recording: $error');
  String get tapToRecord => _t('Toca para grabar (máx. 30s)', 'Tap to record (max. 30s)');
  String get unexpectedErrorOccurred => _t('Ocurrió un error inesperado.', 'An unexpected error occurred.');

  // ── Analysis Screen ──
  String get analysisResult => _t('Resultado del Análisis', 'Analysis Result');
  String get cryAnalysis => _t('Análisis de Llanto', 'Cry Analysis');
  String get uploadingVideo => _t('Subiendo video...', 'Uploading video...');
  String get analyzingVideo => _t('Analizando video...', 'Analyzing video...');
  String get preparing => _t('Preparando...', 'Preparing...');
  String get observations => _t('Observaciones', 'Observations');
  String get recommendations => _t('Recomendaciones', 'Recommendations');
  String get confidenceLevel => _t('Nivel de Confianza', 'Confidence Level');
  String confidence(int value) => _t('$value% confianza', '$value% confidence');

  // ── Model Selector ──
  String get selectModel => _t('Seleccionar Modelo', 'Select Model');
  String get chooseAiModel => _t('Elige el modelo de IA', 'Choose AI Model');
  String get selectModelDescription => _t(
        'Selecciona qué modelo de inteligencia artificial analizará el video de tu bebé.',
        'Select which AI model will analyze your baby\'s video.',
      );
  String get nativeVideoAnalysis => _t('Análisis nativo de video completo', 'Native full video analysis');
  String get cryClassification => _t('Clasificación de llanto por tipo', 'Cry classification by type');
  String get integratedAudioDetection => _t('Detección de audio integrada', 'Integrated audio detection');
  String get visualFrameAnalysis => _t('Análisis visual por frames', 'Visual frame analysis');
  String get claudeSonnetModel => _t('Modelo Claude Sonnet', 'Claude Sonnet model');
  String get spectrogramExtraction => _t('Extracción de espectrograma', 'Spectrogram extraction');
  String get startAnalysis => _t('Iniciar Análisis', 'Start Analysis');
  String get recommended => _t('Recomendado', 'Recommended');

  // ── Traffic Light ──
  String get statusNormal => _t('Normal', 'Normal');
  String get needsAttention => _t('Requiere Atención', 'Needs Attention');
  String get urgent => _t('Urgente', 'Urgent');

  // ── Back/Cancel buttons ──
  String get back => _t('Volver', 'Back');

  // ── Video Capture ──
  String get videoSelectionCancelled => _t('Selección de video cancelada por el usuario.', 'Video selection cancelled by user.');

  // ── Splash ──
  String get splashTagline => _t('Tu bebé te habla. Nosotros te ayudamos a entenderlo.', 'Your baby speaks to you. We help you understand it.');
  String get acceptAndContinue => _t('Aceptar y continuar', 'Accept and continue');

  // ── Analysis Provider ──
  String get geminiDescription => _t('Análisis visual con extracción de frames', 'Visual analysis with frame extraction');
  String get bedrockDescription => _t('Análisis nativo de video y audio con clasificación de llanto', 'Native video and audio analysis with cry classification');

  // ── Landing Page extras ──
  String get challengeDescription => _t(
        'Cada llanto de un bebé tiene un significado. Los padres primerizos '
            'enfrentan noches de incertidumbre preguntándose si todo está bien. '
            'BabyHealth usa inteligencia artificial para ayudarte a interpretar '
            'las señales de tu bebé.',
        'Every baby cry has a meaning. New parents face nights of uncertainty '
            'wondering if everything is okay. BabyHealth uses artificial intelligence '
            'to help you interpret your baby\'s signals.',
      );
  String get statNonUrgent => _t(
        'El 70% de las consultas nocturnas son por causas no urgentes',
        '70% of nighttime consultations are for non-urgent causes',
      );
  String get jaundiceStats => _t(
        'La ictericia neonatal afecta al 60% de los recién nacidos',
        'Neonatal jaundice affects 60% of newborns',
      );
  String get statAnxiety => _t(
        'La ansiedad parental es la principal causa de visitas a urgencias',
        'Parental anxiety is the main cause of emergency room visits',
      );
  String get itsTime => _t('Son las 2:37 AM', "It's 2:37 AM");
  String get parentQuestion => _t(
        '"¿Por qué llora así? ¿Es normal este color?"',
        '"Why is the baby crying like this? Is this color normal?"',
      );
  String get infraAsCode => _t('📦 Infra como código (CDK)', '📦 Infra as code (CDK)');
  String get securityAndPrivacy => _t('Seguridad y Privacidad', 'Security and Privacy');
  String get noStoragePrefix => _t('Sin almacenamiento permanente de ', 'No permanent storage of ');
  String get noImageStorage => _t(
        'imágenes ni videos de tu bebé.',
        'images or videos of your baby.',
      );
  String get encryptedTransmission => _t(
        'Transmisión cifrada: Todos los datos se transmiten de forma segura.',
        'Encrypted transmission: All data is transmitted securely.',
      );
  String get medicalDisclaimer => _t(
        'Descargo médico: Esta aplicación no reemplaza la evaluación de un '
            'profesional de la salud. Consulte a su pediatra ante cualquier preocupación.',
        'Medical disclaimer: This app does not replace evaluation by a health '
            'professional. Consult your pediatrician with any concern.',
      );
  String get readyToTry => _t('¿Listo para probar BabyHealth?', 'Ready to try BabyHealth?');
  String get ctaSubtitle => _t(
        'Crea tu cuenta gratis y comienza a usar BabyHealth hoy mismo.',
        'Create your free account and start using BabyHealth today.',
      );
  String get createFreeAccount => _t('Crear cuenta gratis', 'Create free account');
  String get privacyPoint => _t(
        'Privacidad total: No almacenamos permanentemente imágenes ni videos de tu bebé.',
        'Total privacy: We do not permanently store images or videos of your baby.',
      );
  String get encryptionPoint => _t(
        'Transmisión cifrada: Todos los datos se transmiten de forma segura mediante HTTPS y pre-signed URLs.',
        'Encrypted transmission: All data is transmitted securely via HTTPS and pre-signed URLs.',
      );
  String get disclaimerPoint => _t(
        'Descargo médico: Esta aplicación no reemplaza la evaluación de un profesional de la salud. Consulte a su pediatra ante cualquier preocupación.',
        'Medical disclaimer: This app does not replace evaluation by a health professional. Consult your pediatrician with any concern.',
      );
  String get footerDisclaimer => _t(
        'Esta aplicación no reemplaza la evaluación de un profesional de la salud. '
            'Consulte a un pediatra ante cualquier preocupación sobre la salud de su bebé.',
        'This app does not replace evaluation by a health professional. '
            'Consult a pediatrician with any concern about your baby\'s health.',
      );

  // ── Footer ──
  String get footerTagline => _t(
        'Asistente de cuidado neonatal con IA multimodal.',
        'Multimodal AI neonatal care assistant.',
      );

  // ── Disclaimer Widget ──
  String get importantNotice => _t('Aviso importante', 'Important notice');
  String get fullDisclaimer => _t(
        'Esta aplicación proporciona una orientación preliminar '
            'basada en inteligencia artificial y NO reemplaza la '
            'evaluación de un profesional de la salud. \n\n'
            'Los resultados generados son indicativos y no '
            'constituyen un diagnóstico médico. Si tiene alguna '
            'preocupación sobre la salud de su bebé, consulte '
            'inmediatamente a un pediatra o acuda al centro de '
            'salud más cercano. '
            'Al aceptar, usted reconoce haber leído y comprendido '
            'este aviso.',
        'This app provides preliminary guidance based on artificial '
            'intelligence and does NOT replace evaluation by a health '
            'professional. \n\n'
            'The generated results are indicative and do not constitute '
            'a medical diagnosis. If you have any concerns about your '
            'baby\'s health, please consult a pediatrician immediately '
            'or go to the nearest health center. '
            'By accepting, you acknowledge that you have read and '
            'understood this notice.',
      );
  String get compactDisclaimer => _t(
        'Esta aplicación proporciona orientación preliminar '
            'basada en IA y NO reemplaza la evaluación de un '
            'profesional de la salud. Consulte a un pediatra ante '
            'cualquier preocupación.',
        'This app provides AI-based preliminary guidance and does NOT '
            'replace evaluation by a health professional. Consult a '
            'pediatrician with any concern.',
      );
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['es', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Shorthand: `context.l10n.<key>`.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
