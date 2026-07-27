# Web Auth Cognito Integration - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Cognito authentication to the BabyHealth web landing page with functional navigation buttons and smooth scrolling.

**Architecture:** AWS Amplify Flutter SDK wraps Cognito auth. AuthService provides the API, AuthViewModel manages UI state with Provider. Landing page buttons navigate to `/auth`, nav links smooth-scroll to sections.

**Tech Stack:** Flutter 3.x, Amplify Flutter 2.x, Provider, Cognito User Pool (already deployed)

## Global Constraints

- Flutter SDK: >=3.1.0
- Amplify Flutter: ^2.0.0
- Follow existing MVVM pattern in `frontend/lib/`
- Use existing color scheme: primary `#389BB0`, background `#FAF7F4`
- Spanish language for user-facing text
- All auth errors must show user-friendly messages

---

## File Structure

```
frontend/lib/
├── main.dart                          # [MODIFY] Add routes, AuthService init
├── core/
│   └── amplify_config.dart            # [CREATE] Amplify JSON config
├── services/
│   ├── auth_service.dart              # [CREATE] Amplify auth wrapper
│   └── http_client.dart               # [MODIFY] Add JWT headers
├── viewmodels/
│   └── auth_viewmodel.dart            # [CREATE] Auth state management
├── views/
│   ├── web_landing_screen.dart        # [MODIFY] Buttons + smooth scroll
│   ├── auth_screen.dart               # [CREATE] Login/Signup tabs
│   └── verify_email_screen.dart       # [CREATE] Code confirmation
└── widgets/
    └── auth_text_field.dart           # [CREATE] Styled input widget
```

---

### Task 1: Add Amplify Dependencies

**Files:**
- Modify: `frontend/pubspec.yaml`

**Interfaces:**
- Consumes: None
- Produces: Amplify packages available for import

- [ ] **Step 1: Add dependencies to pubspec.yaml**

Open `frontend/pubspec.yaml` and add under `dependencies:`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # ... existing dependencies ...
  amplify_flutter: ^2.0.0
  amplify_auth_cognito: ^2.0.0
```

- [ ] **Step 2: Install dependencies**

Run:
```bash
cd /Users/hectormartinez/hackathon-Kiro/frontend && flutter pub get
```

Expected: "Got dependencies!" with no errors

- [ ] **Step 3: Commit**

```bash
git add frontend/pubspec.yaml
git commit -m "deps: add amplify_flutter and amplify_auth_cognito"
```

---

### Task 2: Create Amplify Configuration

**Files:**
- Create: `frontend/lib/core/amplify_config.dart`

**Interfaces:**
- Consumes: CDK outputs (UserPoolId, UserPoolClientId, Region)
- Produces: `amplifyConfig` constant string for Amplify initialization

- [ ] **Step 1: Create amplify_config.dart**

Create file `frontend/lib/core/amplify_config.dart`:

```dart
/// Amplify configuration for Cognito User Pool.
///
/// Values from CDK stack outputs:
/// - UserPoolId: from `cdk deploy` BabyHealthStack.UserPoolId
/// - UserPoolClientId: from `cdk deploy` BabyHealthStack.UserPoolClientId
/// - Region: us-east-1 (or your deployed region)
const amplifyConfig = '''{
  "UserAgent": "aws-amplify-cli/0.1.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "UserAgent": "aws-amplify-cli/0.1.0",
        "Version": "1.0",
        "CognitoUserPool": {
          "Default": {
            "PoolId": "us-east-1_XXXXXXXXX",
            "AppClientId": "XXXXXXXXXXXXXXXXXXXXXXXXXX",
            "Region": "us-east-1"
          }
        },
        "Auth": {
          "Default": {
            "authenticationFlowType": "USER_SRP_AUTH"
          }
        }
      }
    }
  }
}''';
```

Note: Replace `PoolId` and `AppClientId` with actual values from CDK outputs after deploy.

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/core/amplify_config.dart
git commit -m "feat: add Amplify configuration for Cognito"
```

---

### Task 3: Create AuthService

**Files:**
- Create: `frontend/lib/services/auth_service.dart`
- Test: `frontend/test/services/auth_service_test.dart`

**Interfaces:**
- Consumes: `amplifyConfig` from `core/amplify_config.dart`
- Produces:
  - `AuthService.configure()` → `Future<void>`
  - `AuthService.signIn(String email, String password)` → `Future<AuthResult>`
  - `AuthService.signUp(String email, String password)` → `Future<AuthResult>`
  - `AuthService.confirmSignUp(String email, String code)` → `Future<AuthResult>`
  - `AuthService.signOut()` → `Future<void>`
  - `AuthService.getCurrentUser()` → `Future<String?>`
  - `AuthService.getAccessToken()` → `Future<String?>`
  - `AuthResult` class with `isSuccess`, `error`, `needsConfirmation`

- [ ] **Step 1: Write failing test for AuthResult**

Create `frontend/test/services/auth_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/auth_service.dart';

void main() {
  group('AuthResult', () {
    test('success result has isSuccess true', () {
      final result = AuthResult.success();
      expect(result.isSuccess, true);
      expect(result.error, isNull);
      expect(result.needsConfirmation, false);
    });

    test('failure result has isSuccess false with error', () {
      final result = AuthResult.failure('Invalid password');
      expect(result.isSuccess, false);
      expect(result.error, 'Invalid password');
      expect(result.needsConfirmation, false);
    });

    test('needsConfirmation result has flag set', () {
      final result = AuthResult.confirmationRequired();
      expect(result.isSuccess, true);
      expect(result.needsConfirmation, true);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
cd /Users/hectormartinez/hackathon-Kiro/frontend && flutter test test/services/auth_service_test.dart
```

Expected: FAIL - cannot find `auth_service.dart`

- [ ] **Step 3: Create AuthService with AuthResult**

Create `frontend/lib/services/auth_service.dart`:

```dart
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

    return 'Algo salió mal. Intenta de nuevo.';
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
cd /Users/hectormartinez/hackathon-Kiro/frontend && flutter test test/services/auth_service_test.dart
```

Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/services/auth_service.dart frontend/test/services/auth_service_test.dart
git commit -m "feat: add AuthService with Cognito integration"
```

---

### Task 4: Create AuthViewModel

**Files:**
- Create: `frontend/lib/viewmodels/auth_viewmodel.dart`
- Test: `frontend/test/viewmodels/auth_viewmodel_test.dart`

**Interfaces:**
- Consumes: `AuthService` from `services/auth_service.dart`
- Produces:
  - `AuthViewModel.state` → `AuthState` enum (unknown, authenticated, unauthenticated)
  - `AuthViewModel.isLoading` → `bool`
  - `AuthViewModel.errorMessage` → `String?`
  - `AuthViewModel.pendingEmail` → `String?`
  - `AuthViewModel.login(email, password)` → `Future<bool>`
  - `AuthViewModel.register(email, password)` → `Future<bool>`
  - `AuthViewModel.verifyCode(code)` → `Future<bool>`
  - `AuthViewModel.checkAuthStatus()` → `Future<void>`

- [ ] **Step 1: Write failing test for AuthViewModel**

Create `frontend/test/viewmodels/auth_viewmodel_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/viewmodels/auth_viewmodel.dart';
import 'package:frontend/services/auth_service.dart';

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
    return AuthResult.failure('Test error');
  }

  @override
  Future<AuthResult> signUp(String email, String password) async {
    if (shouldSucceed) {
      if (shouldNeedConfirmation) {
        return AuthResult.confirmationRequired();
      }
      return AuthResult.success();
    }
    return AuthResult.failure('Test error');
  }

  @override
  Future<AuthResult> confirmSignUp(String email, String code) async {
    if (shouldSucceed) {
      currentUser = email;
      return AuthResult.success();
    }
    return AuthResult.failure('Test error');
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
      expect(viewModel.errorMessage, isNull);
    });

    test('login success sets state to authenticated', () async {
      mockAuthService.shouldSucceed = true;

      final result = await viewModel.login('test@example.com', 'password123');

      expect(result, true);
      expect(viewModel.state, AuthState.authenticated);
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, isNull);
    });

    test('login failure sets error message', () async {
      mockAuthService.shouldSucceed = false;

      final result = await viewModel.login('test@example.com', 'wrongpass');

      expect(result, false);
      expect(viewModel.state, AuthState.unauthenticated);
      expect(viewModel.errorMessage, 'Test error');
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
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
cd /Users/hectormartinez/hackathon-Kiro/frontend && flutter test test/viewmodels/auth_viewmodel_test.dart
```

Expected: FAIL - cannot find `auth_viewmodel.dart`

- [ ] **Step 3: Create AuthViewModel**

Create `frontend/lib/viewmodels/auth_viewmodel.dart`:

```dart
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
  /// Returns true on success, false on failure.
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
  /// Returns true on success (may need confirmation), false on failure.
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
  /// Returns true on success, false on failure.
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
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
cd /Users/hectormartinez/hackathon-Kiro/frontend && flutter test test/viewmodels/auth_viewmodel_test.dart
```

Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/viewmodels/auth_viewmodel.dart frontend/test/viewmodels/auth_viewmodel_test.dart
git commit -m "feat: add AuthViewModel for auth state management"
```

---

### Task 5: Create Auth UI Widgets

**Files:**
- Create: `frontend/lib/widgets/auth_text_field.dart`

**Interfaces:**
- Consumes: None
- Produces:
  - `AuthTextField` widget with label, controller, obscure, keyboardType, validator

- [ ] **Step 1: Create AuthTextField widget**

Create `frontend/lib/widgets/auth_text_field.dart`:

```dart
import 'package:flutter/material.dart';

/// Styled text field for authentication forms.
class AuthTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF2B2826),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 14,
          color: const Color(0xFF2B2826).withOpacity(0.6),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E0DA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E0DA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF389BB0), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE87055)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

/// Email validator.
String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'El email es requerido';
  }
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(value.trim())) {
    return 'Ingresa un email válido';
  }
  return null;
}

/// Password validator (min 8 chars, 1 lowercase, 1 digit).
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'La contraseña es requerida';
  }
  if (value.length < 8) {
    return 'Mínimo 8 caracteres';
  }
  if (!value.contains(RegExp(r'[a-z]'))) {
    return 'Debe contener al menos una minúscula';
  }
  if (!value.contains(RegExp(r'[0-9]'))) {
    return 'Debe contener al menos un número';
  }
  return null;
}
```

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/widgets/auth_text_field.dart
git commit -m "feat: add AuthTextField widget with validators"
```

---

### Task 6: Create AuthScreen

**Files:**
- Create: `frontend/lib/views/auth_screen.dart`

**Interfaces:**
- Consumes: `AuthViewModel`, `AuthTextField`, validators
- Produces: `/auth` route screen with Login/Signup tabs

- [ ] **Step 1: Create AuthScreen**

Create `frontend/lib/views/auth_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/babyhealth_logo_widget.dart';

/// Authentication screen with Login and Signup tabs.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // Login controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Signup controllers
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();

  bool _obscureLoginPassword = true;
  bool _obscureSignupPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Check if we should open signup tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == 'signup') {
        _tabController.animateTo(1);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    final viewModel = context.read<AuthViewModel>();
    viewModel.clearError();

    final success = await viewModel.login(
      _loginEmailController.text,
      _loginPasswordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Future<void> _handleSignup() async {
    if (!_signupFormKey.currentState!.validate()) return;

    if (_signupPasswordController.text != _signupConfirmPasswordController.text) {
      context.read<AuthViewModel>()._setError('Las contraseñas no coinciden');
      return;
    }

    final viewModel = context.read<AuthViewModel>();
    viewModel.clearError();

    final success = await viewModel.register(
      _signupEmailController.text,
      _signupPasswordController.text,
    );

    if (success && mounted) {
      if (viewModel.pendingEmail != null) {
        Navigator.of(context).pushNamed('/verify-email');
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2B2826)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  const BabyHealthLogoWidget(size: 64),
                  const SizedBox(height: 12),
                  const Text(
                    'BabyHealth',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B2826),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tab bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E0DA).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: const Color(0xFF389BB0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF2B2826),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(text: 'Ingresar'),
                        Tab(text: 'Registrarse'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  Consumer<AuthViewModel>(
                    builder: (context, vm, _) {
                      if (vm.errorMessage == null) return const SizedBox.shrink();
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE87055).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFE87055).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Color(0xFFE87055),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                vm.errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFE87055),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Tab content
                  SizedBox(
                    height: 320,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLoginForm(),
                        _buildSignupForm(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          AuthTextField(
            label: 'Email',
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            validator: validateEmail,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: 'Contraseña',
            controller: _loginPasswordController,
            obscureText: _obscureLoginPassword,
            validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureLoginPassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF2B2826).withOpacity(0.5),
              ),
              onPressed: () {
                setState(() => _obscureLoginPassword = !_obscureLoginPassword);
              },
            ),
          ),
          const SizedBox(height: 24),
          Consumer<AuthViewModel>(
            builder: (context, vm, _) {
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: vm.isLoading ? null : _handleLogin,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF389BB0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: vm.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _tabController.animateTo(1),
            child: const Text(
              '¿No tienes cuenta? Regístrate',
              style: TextStyle(color: Color(0xFF389BB0)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _signupFormKey,
      child: Column(
        children: [
          AuthTextField(
            label: 'Email',
            controller: _signupEmailController,
            keyboardType: TextInputType.emailAddress,
            validator: validateEmail,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: 'Contraseña',
            controller: _signupPasswordController,
            obscureText: _obscureSignupPassword,
            validator: validatePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureSignupPassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF2B2826).withOpacity(0.5),
              ),
              onPressed: () {
                setState(() => _obscureSignupPassword = !_obscureSignupPassword);
              },
            ),
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: 'Confirmar contraseña',
            controller: _signupConfirmPasswordController,
            obscureText: _obscureConfirmPassword,
            validator: (v) {
              if (v?.isEmpty == true) return 'Requerido';
              if (v != _signupPasswordController.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF2B2826).withOpacity(0.5),
              ),
              onPressed: () {
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
              },
            ),
          ),
          const SizedBox(height: 24),
          Consumer<AuthViewModel>(
            builder: (context, vm, _) {
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: vm.isLoading ? null : _handleSignup,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF389BB0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: vm.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Crear cuenta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/views/auth_screen.dart
git commit -m "feat: add AuthScreen with Login/Signup tabs"
```

---

### Task 7: Create VerifyEmailScreen

**Files:**
- Create: `frontend/lib/views/verify_email_screen.dart`

**Interfaces:**
- Consumes: `AuthViewModel`
- Produces: `/verify-email` route screen for code confirmation

- [ ] **Step 1: Create VerifyEmailScreen**

Create `frontend/lib/views/verify_email_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';

/// Screen for email verification code entry.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<AuthViewModel>();
    viewModel.clearError();

    final success = await viewModel.verifyCode(_codeController.text.trim());

    if (success && mounted) {
      // Show success message then navigate
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Email verificado! Inicia sesión para continuar.'),
          backgroundColor: Color(0xFF389BB0),
        ),
      );
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  Future<void> _handleResend() async {
    final viewModel = context.read<AuthViewModel>();
    final success = await viewModel.resendCode();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código reenviado a tu email'),
          backgroundColor: Color(0xFF389BB0),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
    final email = viewModel.pendingEmail ?? 'tu email';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2B2826)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6F2F7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.email_outlined,
                      size: 40,
                      color: Color(0xFF389BB0),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'Verifica tu correo',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B2826),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'Enviamos un código de 6 dígitos a:',
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFF2B2826).withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF389BB0),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error message
                  if (viewModel.errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE87055).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFE87055).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFE87055),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              viewModel.errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFE87055),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Code input
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: Color(0xFF2B2826),
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '000000',
                        hintStyle: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                          color: const Color(0xFF2B2826).withOpacity(0.2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E0DA)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E0DA)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF389BB0),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length != 6) {
                          return 'Ingresa el código de 6 dígitos';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Verify button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: viewModel.isLoading ? null : _handleVerify,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF389BB0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: viewModel.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Verificar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Resend link
                  TextButton(
                    onPressed: viewModel.isLoading ? null : _handleResend,
                    child: const Text(
                      '¿No recibiste el código? Reenviar',
                      style: TextStyle(color: Color(0xFF389BB0)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/views/verify_email_screen.dart
git commit -m "feat: add VerifyEmailScreen for code confirmation"
```

---

### Task 8: Update WebLandingScreen with Buttons and Scroll

**Files:**
- Modify: `frontend/lib/views/web_landing_screen.dart`

**Interfaces:**
- Consumes: Navigation to `/auth`
- Produces: Functional buttons and smooth scroll navigation

- [ ] **Step 1: Update WebLandingScreen to StatefulWidget with GlobalKeys**

Modify `frontend/lib/views/web_landing_screen.dart`. Replace the class definition and add scroll functionality:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/capture_repository.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/babyhealth_logo_widget.dart';
import '../widgets/phone_mockup_widget.dart';
import 'home_screen.dart';

/// Web landing screen with full informational sections and a phone mockup.
class WebLandingScreen extends StatefulWidget {
  const WebLandingScreen({super.key});

  @override
  State<WebLandingScreen> createState() => _WebLandingScreenState();
}

class _WebLandingScreenState extends State<WebLandingScreen> {
  // GlobalKeys for scroll targets
  final _comoFuncionaKey = GlobalKey();
  final _caracteristicasKey = GlobalKey();
  final _arquitecturaKey = GlobalKey();
  final _seguridadKey = GlobalKey();

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToAuth({bool signup = false}) {
    Navigator.of(context).pushNamed(
      '/auth',
      arguments: signup ? 'signup' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F4),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _NavBar(
              onComoFunciona: () => _scrollToSection(_comoFuncionaKey),
              onCaracteristicas: () => _scrollToSection(_caracteristicasKey),
              onArquitectura: () => _scrollToSection(_arquitecturaKey),
              onSeguridad: () => _scrollToSection(_seguridadKey),
              onSolicitarAcceso: () => _navigateToAuth(),
            ),
            _HeroSection(
              onSolicitarAcceso: () => _navigateToAuth(),
              onVerComoFunciona: () => _scrollToSection(_comoFuncionaKey),
            ),
            _DesafioSection(),
            _ComoFuncionaSection(key: _comoFuncionaKey),
            _CaracteristicasSection(key: _caracteristicasKey),
            _ArquitecturaSection(key: _arquitecturaKey),
            _SeguridadSection(key: _seguridadKey),
            _CtaBandSection(onCrearCuenta: () => _navigateToAuth(signup: true)),
            _FooterSection(
              onComoFunciona: () => _scrollToSection(_comoFuncionaKey),
              onCaracteristicas: () => _scrollToSection(_caracteristicasKey),
              onArquitectura: () => _scrollToSection(_arquitecturaKey),
              onSeguridad: () => _scrollToSection(_seguridadKey),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Update _NavBar to accept callbacks**

Replace the `_NavBar` class:

```dart
class _NavBar extends StatelessWidget {
  final VoidCallback onComoFunciona;
  final VoidCallback onCaracteristicas;
  final VoidCallback onArquitectura;
  final VoidCallback onSeguridad;
  final VoidCallback onSolicitarAcceso;

  const _NavBar({
    required this.onComoFunciona,
    required this.onCaracteristicas,
    required this.onArquitectura,
    required this.onSeguridad,
    required this.onSolicitarAcceso,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F4),
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE5E0DA), width: 1),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 768;
                if (isWide) {
                  return _buildDesktopNav(context);
                }
                return _buildMobileNav(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopNav(BuildContext context) {
    return Row(
      children: [
        const BabyHealthLogoWidget(size: 40),
        const SizedBox(width: 12),
        Text(
          'BabyHealth',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2B2826),
          ),
        ),
        const Spacer(),
        _navLink('Cómo funciona', onComoFunciona),
        const SizedBox(width: 24),
        _navLink('Características', onCaracteristicas),
        const SizedBox(width: 24),
        _navLink('Arquitectura', onArquitectura),
        const SizedBox(width: 24),
        _navLink('Seguridad', onSeguridad),
        const SizedBox(width: 32),
        _ctaButton(context),
      ],
    );
  }

  Widget _buildMobileNav(BuildContext context) {
    return Row(
      children: [
        const BabyHealthLogoWidget(size: 32),
        const SizedBox(width: 8),
        Text(
          'BabyHealth',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2B2826),
          ),
        ),
        const Spacer(),
        _ctaButton(context),
      ],
    );
  }

  Widget _navLink(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2B2826).withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _ctaButton(BuildContext context) {
    return FilledButton(
      onPressed: onSolicitarAcceso,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF389BB0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: const Text(
        'Solicitar acceso',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
```

- [ ] **Step 3: Update _HeroSection to accept callbacks**

Update the `_HeroSection` class to accept and use callbacks:

```dart
class _HeroSection extends StatelessWidget {
  final VoidCallback onSolicitarAcceso;
  final VoidCallback onVerComoFunciona;

  const _HeroSection({
    required this.onSolicitarAcceso,
    required this.onVerComoFunciona,
  });

  // ... keep existing build method but update the buttons in _buildHeroText:

  Widget _buildHeroText(BuildContext context) {
    final isLarge = MediaQuery.of(context).size.width >= 768;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ... existing chip and title code ...

        // Double buttons - UPDATE THIS PART
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton(
              onPressed: onSolicitarAcceso,  // Changed from () {}
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF389BB0),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: const Text('Solicitar acceso →'),
            ),
            OutlinedButton(
              onPressed: onVerComoFunciona,  // Changed from () {}
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2B2826),
                side: BorderSide(
                  color: const Color(0xFF2B2826).withOpacity(0.3),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: const Text('Ver cómo funciona'),
            ),
          ],
        ),
        // ... rest of the method ...
      ],
    );
  }
}
```

- [ ] **Step 4: Update _CtaBandSection to use registration button**

Replace the `_CtaBandSection` class:

```dart
class _CtaBandSection extends StatelessWidget {
  final VoidCallback onCrearCuenta;

  const _CtaBandSection({required this.onCrearCuenta});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFAF7F4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Container(
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF389BB0), Color(0xFF2D7E91)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF389BB0).withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '¿Listo para probar BabyHealth?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Crea tu cuenta gratis y comienza a usar BabyHealth hoy mismo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.85),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: onCrearCuenta,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF389BB0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Crear cuenta gratis →'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Update _FooterSection to accept scroll callbacks**

Update `_FooterSection` to accept and use callbacks for footer links:

```dart
class _FooterSection extends StatelessWidget {
  final VoidCallback onComoFunciona;
  final VoidCallback onCaracteristicas;
  final VoidCallback onArquitectura;
  final VoidCallback onSeguridad;

  const _FooterSection({
    required this.onComoFunciona,
    required this.onCaracteristicas,
    required this.onArquitectura,
    required this.onSeguridad,
  });

  // ... keep existing build and layout methods, but update _footerLink calls:

  Widget _footerLink(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  // In _buildDesktopFooter and _buildMobileFooter, update calls like:
  // _footerLink('Cómo funciona', onComoFunciona),
  // _footerLink('Características', onCaracteristicas),
  // etc.
}
```

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/views/web_landing_screen.dart
git commit -m "feat: add functional buttons and smooth scroll to landing page"
```

---

### Task 9: Update main.dart with Routes and AuthService

**Files:**
- Modify: `frontend/lib/main.dart`

**Interfaces:**
- Consumes: `AuthService`, `AuthViewModel`, `AuthScreen`, `VerifyEmailScreen`
- Produces: Complete app with auth routes and Amplify initialization

- [ ] **Step 1: Update main.dart with auth integration**

Replace `frontend/lib/main.dart`:

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_config.dart';
import 'models/analysis_config.dart';
import 'models/captured_media.dart';
import 'repositories/analysis_repository.dart';
import 'repositories/capture_repository.dart';
import 'repositories/upload_repository.dart';
import 'services/auth_service.dart';
import 'services/http_client.dart';
import 'services/platform_service.dart';
import 'services/storage_service.dart';
import 'services/video_capture_service.dart';
import 'viewmodels/analysis_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/splash_viewmodel.dart';
import 'views/analysis_screen.dart';
import 'views/auth_screen.dart';
import 'views/home_screen.dart';
import 'views/model_selector_screen.dart';
import 'views/splash_screen.dart';
import 'views/verify_email_screen.dart';
import 'views/web_landing_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AuthService and configure Amplify
  final authService = AuthService();
  try {
    await authService.configure();
  } catch (e) {
    debugPrint('Amplify configuration error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        // -- Auth service (singleton) --
        Provider<AuthService>.value(value: authService),

        // -- Core services --
        Provider<PlatformService>(create: (_) => PlatformService()),
        ProxyProvider<AuthService, HttpClient>(
          update: (_, authService, previous) =>
              previous ??
              HttpClient(
                baseUrl: ApiConfig.baseUrl,
                authService: authService,
              ),
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
              previous ?? CaptureRepository(videoCaptureService: service),
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
              previous ?? AnalysisRepository(httpClient: httpClient),
        ),

        // -- ViewModels --
        ChangeNotifierProvider<SplashViewModel>(
          create: (_) => SplashViewModel(),
        ),
        ChangeNotifierProxyProvider<AuthService, AuthViewModel>(
          create: (context) => AuthViewModel(
            authService: context.read<AuthService>(),
          ),
          update: (_, authService, previous) =>
              previous ?? AuthViewModel(authService: authService),
        ),
        ChangeNotifierProvider<HomeViewModel>(
          create: (context) => HomeViewModel(
            captureRepository: context.read<CaptureRepository>(),
          ),
        ),
        ChangeNotifierProvider<AnalysisViewModel>(
          create: (context) => AnalysisViewModel(
            uploadRepository: context.read<UploadRepository>(),
            analysisRepository: context.read<AnalysisRepository>(),
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
      initialRoute: kIsWeb ? '/web-landing' : '/splash',
      routes: {
        if (kIsWeb) '/web-landing': (_) => const WebLandingScreen(),
        '/splash': (_) => const SplashScreen(),
        '/home': (_) => const HomeScreen(),
        '/auth': (_) => const AuthScreen(),
        '/verify-email': (_) => const VerifyEmailScreen(),
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
```

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/main.dart
git commit -m "feat: integrate auth routes and AuthService initialization"
```

---

### Task 10: Update HttpClient with JWT Headers

**Files:**
- Modify: `frontend/lib/services/http_client.dart`

**Interfaces:**
- Consumes: `AuthService.getAccessToken()`
- Produces: HTTP requests with Authorization header when authenticated

- [ ] **Step 1: Update HttpClient to include JWT**

Modify `frontend/lib/services/http_client.dart` to add auth support:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

/// HTTP client with base URL and optional JWT authentication.
class HttpClient {
  final String baseUrl;
  final AuthService? authService;
  final http.Client _client;

  HttpClient({
    required this.baseUrl,
    this.authService,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (authService != null) {
      final token = await authService!.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<http.Response> get(String path) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$path');
    return _client.get(uri, headers: headers);
  }

  Future<http.Response> post(String path, {Object? body}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$path');
    return _client.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> put(String path, {Object? body}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$path');
    return _client.put(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(String path) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$path');
    return _client.delete(uri, headers: headers);
  }

  void close() {
    _client.close();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/services/http_client.dart
git commit -m "feat: add JWT authorization headers to HttpClient"
```

---

### Task 11: Final Integration Test

**Files:**
- None (manual testing)

**Interfaces:**
- Consumes: All previous tasks
- Produces: Working auth flow

- [ ] **Step 1: Run Flutter web app**

```bash
cd /Users/hectormartinez/hackathon-Kiro/frontend && flutter run -d chrome --web-port=8080
```

- [ ] **Step 2: Manual test checklist**

Test the following in browser at http://localhost:8080:

1. [ ] Landing page loads correctly
2. [ ] "Cómo funciona" nav link scrolls to section
3. [ ] "Características" nav link scrolls to section
4. [ ] "Arquitectura" nav link scrolls to section
5. [ ] "Seguridad" nav link scrolls to section
6. [ ] "Solicitar acceso" button navigates to /auth
7. [ ] "Ver cómo funciona" button scrolls to section
8. [ ] CTA "Crear cuenta gratis" navigates to /auth with signup tab
9. [ ] Login form validates email format
10. [ ] Login form validates password required
11. [ ] Signup form validates password policy
12. [ ] Signup form validates password confirmation match
13. [ ] Back button on auth screen returns to landing

- [ ] **Step 3: Commit final state**

```bash
git add -A
git commit -m "feat: complete web auth integration with Cognito

- Add Amplify Flutter SDK for Cognito auth
- Create AuthService with signIn, signUp, confirmSignUp
- Create AuthViewModel for state management
- Add AuthScreen with Login/Signup tabs
- Add VerifyEmailScreen for code confirmation
- Update landing page with functional buttons
- Add smooth scroll navigation
- Integrate JWT tokens in HttpClient

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Summary

| Task | Description | Files |
|------|-------------|-------|
| 1 | Add Amplify dependencies | pubspec.yaml |
| 2 | Create Amplify config | amplify_config.dart |
| 3 | Create AuthService | auth_service.dart + test |
| 4 | Create AuthViewModel | auth_viewmodel.dart + test |
| 5 | Create Auth UI widgets | auth_text_field.dart |
| 6 | Create AuthScreen | auth_screen.dart |
| 7 | Create VerifyEmailScreen | verify_email_screen.dart |
| 8 | Update WebLandingScreen | web_landing_screen.dart |
| 9 | Update main.dart | main.dart |
| 10 | Update HttpClient | http_client.dart |
| 11 | Integration test | Manual testing |

**Total new files:** 7
**Total modified files:** 3
**Estimated commits:** 11
