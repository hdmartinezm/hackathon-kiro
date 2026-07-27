import 'package:flutter_test/flutter_test.dart';
import 'package:babyhealth/core/app_localizations.dart';
import 'package:babyhealth/services/auth_service.dart';

void main() {
  group('AuthResult', () {
    test('success result has isSuccess true', () {
      final result = AuthResult.success();
      expect(result.isSuccess, true);
      expect(result.errorCode, isNull);
      expect(result.needsConfirmation, false);
    });

    test('failure result has isSuccess false with error', () {
      final result = AuthResult.failure(AuthErrorCode.incorrectCredentials);
      expect(result.isSuccess, false);
      expect(result.errorCode, AuthErrorCode.incorrectCredentials);
      expect(result.needsConfirmation, false);
    });

    test('needsConfirmation result has flag set', () {
      final result = AuthResult.confirmationRequired();
      expect(result.isSuccess, true);
      expect(result.needsConfirmation, true);
    });
  });
}
