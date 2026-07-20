import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// Result of an authentication operation.
class AuthResult {
  final bool success;
  final String? error;
  final bool needsConfirmation;

  AuthResult({
    required this.success,
    this.error,
    this.needsConfirmation = false,
  });
}

/// Service for handling authentication with Cognito.
///
/// Wraps Amplify Auth plugin with error handling and
/// Spanish error messages for the UI.
class AuthService {
  /// Signs up a new user with email and password.
  ///
  /// Returns [AuthResult] with needsConfirmation=true if email
  /// verification is required.
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: email,
          },
        ),
      );

      return AuthResult(
        success: result.isSignUpComplete,
        needsConfirmation: !result.isSignUpComplete,
      );
    } on UsernameExistsException {
      return AuthResult(
        success: false,
        error: 'Este email ya está registrado. Intenta iniciar sesión.',
      );
    } on InvalidPasswordException catch (e) {
      return AuthResult(
        success: false,
        error: 'Contraseña inválida: ${_parsePasswordError(e.message)}',
      );
    } on AuthException catch (e) {
      return AuthResult(
        success: false,
        error: 'Error de registro: ${e.message}',
      );
    }
  }

  /// Confirms sign up with the verification code sent to email.
  Future<AuthResult> confirmSignUp({
    required String email,
    required String code,
  }) async {
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: code,
      );

      return AuthResult(success: result.isSignUpComplete);
    } on CodeMismatchException {
      return AuthResult(
        success: false,
        error: 'Código incorrecto. Verifica e intenta de nuevo.',
      );
    } on ExpiredCodeException {
      return AuthResult(
        success: false,
        error: 'Código expirado. Solicita uno nuevo.',
      );
    } on AuthException catch (e) {
      return AuthResult(
        success: false,
        error: 'Error de verificación: ${e.message}',
      );
    }
  }

  /// Resends the confirmation code to the user's email.
  Future<AuthResult> resendConfirmationCode({required String email}) async {
    try {
      await Amplify.Auth.resendSignUpCode(username: email);
      return AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult(
        success: false,
        error: 'No se pudo reenviar el código: ${e.message}',
      );
    }
  }

  /// Signs in a user with email and password.
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );

      if (result.isSignedIn) {
        return AuthResult(success: true);
      } else {
        // May need confirmation
        return AuthResult(
          success: false,
          needsConfirmation: true,
          error: 'Debes verificar tu email primero.',
        );
      }
    } on UserNotConfirmedException {
      return AuthResult(
        success: false,
        needsConfirmation: true,
        error: 'Debes verificar tu email primero.',
      );
    } on NotAuthorizedServiceException {
      return AuthResult(
        success: false,
        error: 'Email o contraseña incorrectos.',
      );
    } on UserNotFoundException {
      return AuthResult(
        success: false,
        error: 'No existe una cuenta con este email.',
      );
    } on AuthException catch (e) {
      return AuthResult(
        success: false,
        error: 'Error de inicio de sesión: ${e.message}',
      );
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await Amplify.Auth.signOut();
  }

  /// Checks if a user is currently signed in.
  Future<bool> isSignedIn() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session.isSignedIn;
    } catch (_) {
      return false;
    }
  }

  /// Gets the current user's access token for API calls.
  ///
  /// Returns null if the user is not signed in.
  Future<String?> getAccessToken() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) return null;

      final cognitoSession = session as CognitoAuthSession;
      final tokens = cognitoSession.userPoolTokensResult;

      if (tokens.value == null) return null;

      return tokens.value!.accessToken.raw;
    } catch (_) {
      return null;
    }
  }

  /// Parses password validation errors into Spanish.
  String _parsePasswordError(String message) {
    if (message.contains('length')) {
      return 'debe tener al menos 8 caracteres';
    }
    if (message.contains('lowercase')) {
      return 'debe incluir letras minúsculas';
    }
    if (message.contains('digit') || message.contains('number')) {
      return 'debe incluir números';
    }
    return message;
  }
}
