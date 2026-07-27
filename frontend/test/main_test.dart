import 'package:flutter_test/flutter_test.dart';
import 'package:babyhealth/views/auth_screen.dart';
import 'package:babyhealth/views/verify_email_screen.dart';
import 'package:babyhealth/services/auth_service.dart';
import 'package:babyhealth/viewmodels/auth_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Main App Routes', () {
    test('AuthService can be instantiated', () {
      final authService = AuthService();
      expect(authService, isA<AuthService>());
    });

    test('AuthViewModel can be created with AuthService', () {
      final authService = AuthService();
      final authViewModel = AuthViewModel(authService: authService);
      expect(authViewModel, isA<AuthViewModel>());
    });

    test('AuthScreen is available for routing', () {
      // This test verifies that the screen widgets can be instantiated
      // which confirms they're properly imported and available for routing
      const authScreen = AuthScreen();
      expect(authScreen, isA<AuthScreen>());
    });

    test('VerifyEmailScreen is available for routing', () {
      const verifyEmailScreen = VerifyEmailScreen();
      expect(verifyEmailScreen, isA<VerifyEmailScreen>());
    });
  });
}
