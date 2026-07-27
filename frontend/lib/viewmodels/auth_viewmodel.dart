import 'package:amplify_flutter/amplify_flutter.dart' show AuthProvider;
import 'package:flutter/foundation.dart';

import '../core/app_localizations.dart';
import '../services/auth_service.dart';

/// Authentication states.
enum AuthState {
  unknown,
  authenticated,
  unauthenticated,
}

/// ViewModel for authentication state management.
class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;

  AuthState _state = AuthState.unauthenticated;
  bool _isLoading = false;
  AuthErrorCode? _errorCode;
  String? _errorDetail;
  String? _pendingEmail;

  AuthViewModel({required AuthService authService}) : _authService = authService;

  // Getters
  AuthState get state => _state;
  bool get isLoading => _isLoading;
  AuthErrorCode? get errorCode => _errorCode;
  String? get errorDetail => _errorDetail;
  String? get pendingEmail => _pendingEmail;

  /// Check current authentication status.
  Future<void> checkAuthStatus() async {
    _setLoading(true);

    final user = await _authService.getCurrentUser();

    if (user != null) {
      _state = AuthState.authenticated;
    } else {
      _state = AuthState.unauthenticated;
    }

    _setLoading(false);
  }

  /// Login with email and password.
  Future<bool> login(String email, String password) async {
    _clearError();
    _setLoading(true);

    final result = await _authService.signIn(email, password);

    _setLoading(false);

    if (result.isSuccess) {
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    }

    _setError(result.errorCode ?? AuthErrorCode.loginError, result.errorDetail);
    return false;
  }

  /// Register with email and password.
  Future<bool> register(String email, String password) async {
    _clearError();
    _setLoading(true);

    final result = await _authService.signUp(email, password);

    _setLoading(false);

    if (result.isSuccess) {
      if (result.needsConfirmation) {
        _pendingEmail = email;
        notifyListeners();
      } else {
        _state = AuthState.authenticated;
        notifyListeners();
      }
      return true;
    }

    _setError(result.errorCode ?? AuthErrorCode.registerError, result.errorDetail);
    return false;
  }

  /// Verify email with confirmation code.
  Future<bool> verifyCode(String code) async {
    if (_pendingEmail == null) {
      _setError(AuthErrorCode.noPendingEmail);
      return false;
    }

    _clearError();
    _setLoading(true);

    final result = await _authService.confirmSignUp(_pendingEmail!, code);

    _setLoading(false);

    if (result.isSuccess) {
      // Auto-login after verification
      final loginResult = await _authService.signIn(_pendingEmail!, '');
      if (loginResult.isSuccess) {
        _state = AuthState.authenticated;
        _pendingEmail = null;
        notifyListeners();
        return true;
      }
      // Even if auto-login fails, verification succeeded
      _pendingEmail = null;
      notifyListeners();
      return true;
    }

    _setError(result.errorCode ?? AuthErrorCode.verifyError, result.errorDetail);
    return false;
  }

  /// Resend confirmation code.
  Future<bool> resendCode() async {
    if (_pendingEmail == null) {
      _setError(AuthErrorCode.noPendingEmail);
      return false;
    }

    _clearError();
    _setLoading(true);

    final result = await _authService.resendConfirmationCode(_pendingEmail!);

    _setLoading(false);

    if (result.isSuccess) {
      return true;
    }

    _setError(result.errorCode ?? AuthErrorCode.resendError, result.errorDetail);
    return false;
  }

  /// Login with a federated social provider (Google, Apple, Facebook).
  Future<bool> loginWithProvider(AuthProvider provider) async {
    _clearError();
    _setLoading(true);

    final result = await _authService.signInWithProvider(provider);

    _setLoading(false);

    if (result.isSuccess) {
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    }

    _setError(result.errorCode ?? AuthErrorCode.loginError, result.errorDetail);
    return false;
  }

  /// Logout current user.
  Future<void> logout() async {
    _setLoading(true);
    await _authService.signOut();
    _state = AuthState.unauthenticated;
    _pendingEmail = null;
    _setLoading(false);
  }

  /// Clear any error message.
  void clearError() {
    _clearError();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(AuthErrorCode code, [String? detail]) {
    _errorCode = code;
    _errorDetail = detail;
    notifyListeners();
  }

  void _clearError() {
    _errorCode = null;
    _errorDetail = null;
    notifyListeners();
  }
}
