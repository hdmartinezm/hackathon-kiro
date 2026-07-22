import 'package:flutter/foundation.dart';

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
  String? _errorMessage;
  String? _pendingEmail;

  AuthViewModel({required AuthService authService}) : _authService = authService;

  // Getters
  AuthState get state => _state;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
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

    _setError(result.error ?? 'Error al iniciar sesión');
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

    _setError(result.error ?? 'Error al registrarse');
    return false;
  }

  /// Verify email with confirmation code.
  Future<bool> verifyCode(String code) async {
    if (_pendingEmail == null) {
      _setError('No hay email pendiente de verificación');
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

    _setError(result.error ?? 'Error al verificar código');
    return false;
  }

  /// Resend confirmation code.
  Future<bool> resendCode() async {
    if (_pendingEmail == null) {
      _setError('No hay email pendiente de verificación');
      return false;
    }

    _clearError();
    _setLoading(true);

    final result = await _authService.resendConfirmationCode(_pendingEmail!);

    _setLoading(false);

    if (result.isSuccess) {
      return true;
    }

    _setError(result.error ?? 'Error al reenviar código');
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

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
