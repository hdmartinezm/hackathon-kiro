import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../core/amplify_config.dart';

/// Result of an authentication operation.
class AuthResult {
  final bool isSuccess;
  final String? error;
  final bool needsConfirmation;

  const AuthResult._({
    required this.isSuccess,
    this.error,
    this.needsConfirmation = false,
  });

  factory AuthResult.success() => const AuthResult._(isSuccess: true);

  factory AuthResult.failure(String error) => AuthResult._(
        isSuccess: false,
        error: error,
      );

  factory AuthResult.confirmationRequired() => const AuthResult._(
        isSuccess: true,
        needsConfirmation: true,
      );
}

/// Service for Cognito authentication via Amplify.
class AuthService {
  bool _isConfigured = false;

  /// Configure Amplify with Cognito plugin.
  Future<void> configure() async {
    if (_isConfigured) return;

    try {
      final authPlugin = AmplifyAuthCognito();
      await Amplify.addPlugins([authPlugin]);
      await Amplify.configure(amplifyConfig);
      _isConfigured = true;
    } on AmplifyAlreadyConfiguredException {
      _isConfigured = true;
    }
  }

  /// Sign in with email and password.
  Future<AuthResult> signIn(String email, String password) async {
    try {
      // First sign out any existing session
      try {
        await Amplify.Auth.signOut();
      } catch (_) {}

      final result = await Amplify.Auth.signIn(
        username: email.trim().toLowerCase(),
        password: password,
      );

      if (result.isSignedIn) {
        return AuthResult.success();
      }

      return AuthResult.failure('No se pudo iniciar sesión');
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      return AuthResult.failure('Error inesperado: $e');
    }
  }

  /// Sign up with email and password.
  Future<AuthResult> signUp(String email, String password) async {
    try {
      final result = await Amplify.Auth.signUp(
        username: email.trim().toLowerCase(),
        password: password,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: email.trim().toLowerCase(),
          },
        ),
      );

      if (result.isSignUpComplete) {
        return AuthResult.success();
      }

      return AuthResult.confirmationRequired();
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      return AuthResult.failure('Error inesperado: $e');
    }
  }

  /// Confirm sign up with verification code.
  Future<AuthResult> confirmSignUp(String email, String code) async {
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: email.trim().toLowerCase(),
        confirmationCode: code.trim(),
      );

      if (result.isSignUpComplete) {
        return AuthResult.success();
      }

      return AuthResult.failure('No se pudo verificar el código');
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    }
  }

  /// Resend confirmation code.
  Future<AuthResult> resendConfirmationCode(String email) async {
    try {
      await Amplify.Auth.resendSignUpCode(
        username: email.trim().toLowerCase(),
      );
      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    }
  }

  /// Sign out current user.
  Future<void> signOut() async {
    await Amplify.Auth.signOut();
  }

  /// Get current authenticated user's email, or null if not signed in.
  Future<String?> getCurrentUser() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      return user.username;
    } on AuthException {
      return null;
    }
  }

  /// Get access token for API calls.
  Future<String?> getAccessToken() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession(
        options: const FetchAuthSessionOptions(forceRefresh: false),
      );

      if (session is CognitoAuthSession) {
        return session.userPoolTokensResult.value.accessToken.raw;
      }
      return null;
    } on AuthException {
      return null;
    }
  }

  /// Map Amplify auth exceptions to user-friendly Spanish messages.
  String _mapAuthError(AuthException e) {
    final message = e.message.toLowerCase();

    if (message.contains('user not found') ||
        message.contains('user does not exist')) {
      return 'No existe una cuenta con este email';
    }
    if (message.contains('incorrect') || message.contains('invalid')) {
      return 'Email o contraseña incorrectos';
    }
    if (message.contains('already exists') || message.contains('username exists')) {
      return 'Ya existe una cuenta con este email';
    }
    if (message.contains('invalid code') || message.contains('code mismatch')) {
      return 'Código incorrecto. Intenta de nuevo.';
    }
    if (message.contains('expired')) {
      return 'El código ha expirado. Solicita uno nuevo.';
    }
    if (message.contains('password') && message.contains('policy')) {
      return 'La contraseña debe tener al menos 8 caracteres, una minúscula y un número';
    }
    if (message.contains('network') || message.contains('connection')) {
      return 'Error de conexión. Verifica tu internet.';
    }
    if (message.contains('not configured') || message.contains('amplify')) {
      return 'Error de configuración. Recarga la página.';
    }

    // Debug: show actual error in development
    return 'Error: ${e.message}';
  }
}
