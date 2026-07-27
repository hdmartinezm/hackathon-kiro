import 'package:flutter_test/flutter_test.dart';
import 'package:babyhealth/core/app_localizations.dart';
import 'package:babyhealth/viewmodels/auth_viewmodel.dart';
import 'package:babyhealth/services/auth_service.dart';

// Simple mock for testing
class MockAuthService extends AuthService {
  bool shouldSucceed = true;
  bool shouldNeedConfirmation = false;
  String? currentUser;

  @override
  Future<void> configure() async {}

  @override
  Future<AuthResult> signIn(String email, String password) async {
    if (shouldSucceed) {
      currentUser = email;
      return AuthResult.success();
    }
    return AuthResult.failure(AuthErrorCode.incorrectCredentials);
  }

  @override
  Future<AuthResult> signUp(String email, String password) async {
    if (shouldSucceed) {
      if (shouldNeedConfirmation) {
        return AuthResult.confirmationRequired();
      }
      return AuthResult.success();
    }
    return AuthResult.failure(AuthErrorCode.registerError);
  }

  @override
  Future<AuthResult> confirmSignUp(String email, String code) async {
    if (shouldSucceed) {
      currentUser = email;
      return AuthResult.success();
    }
    return AuthResult.failure(AuthErrorCode.verifyError);
  }

  @override
  Future<String?> getCurrentUser() async => currentUser;

  @override
  Future<void> signOut() async {
    currentUser = null;
  }
}

void main() {
  group('AuthViewModel', () {
    late MockAuthService mockAuthService;
    late AuthViewModel viewModel;

    setUp(() {
      mockAuthService = MockAuthService();
      viewModel = AuthViewModel(authService: mockAuthService);
    });

    test('initial state is unauthenticated', () {
      expect(viewModel.state, AuthState.unauthenticated);
      expect(viewModel.isLoading, false);
      expect(viewModel.errorCode, isNull);
    });

    test('login success sets state to authenticated', () async {
      mockAuthService.shouldSucceed = true;

      final result = await viewModel.login('test@example.com', 'password123');

      expect(result, true);
      expect(viewModel.state, AuthState.authenticated);
      expect(viewModel.isLoading, false);
      expect(viewModel.errorCode, isNull);
    });

    test('login failure sets error code', () async {
      mockAuthService.shouldSucceed = false;

      final result = await viewModel.login('test@example.com', 'wrongpass');

      expect(result, false);
      expect(viewModel.state, AuthState.unauthenticated);
      expect(viewModel.errorCode, AuthErrorCode.incorrectCredentials);
    });

    test('register with confirmation sets pendingEmail', () async {
      mockAuthService.shouldSucceed = true;
      mockAuthService.shouldNeedConfirmation = true;

      final result = await viewModel.register('test@example.com', 'password123');

      expect(result, true);
      expect(viewModel.pendingEmail, 'test@example.com');
    });
  });
}
