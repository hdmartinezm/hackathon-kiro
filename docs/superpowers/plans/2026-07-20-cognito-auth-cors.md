# Cognito Auth + CORS Restrictivo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar autenticación con AWS Cognito User Pools y CORS restrictivo para BabyHealth.

**Architecture:** API Gateway Cognito Authorizer valida JWT antes de Lambda. Flutter usa Amplify Auth para registro/login. CORS rechaza browsers (solo apps nativas).

**Tech Stack:** AWS CDK (Python), AWS Cognito, API Gateway HTTP API, Flutter, Amplify Auth

## Global Constraints

- AWS Region: `us-east-1`
- Python: 3.11+
- Flutter SDK: >=3.1.0 <4.0.0
- Cognito password policy: min 8 chars, lowercase, digits
- Endpoints protegidos: `/upload-url`, `/analyze`
- Endpoint público: `/health`

---

## File Structure

### Infrastructure (CDK)
- **Modify:** `infra/stacks/babyhealth_stack.py` - Add Cognito, Authorizer, update CORS and routes

### Flutter App
- **Modify:** `flutter_app/pubspec.yaml` - Add Amplify dependencies
- **Create:** `flutter_app/lib/config/amplify_config.dart` - Cognito configuration
- **Create:** `flutter_app/lib/services/auth_service.dart` - Auth wrapper
- **Create:** `flutter_app/lib/screens/login_screen.dart` - Login UI
- **Create:** `flutter_app/lib/screens/signup_screen.dart` - Signup UI
- **Create:** `flutter_app/lib/screens/verify_email_screen.dart` - Email verification
- **Modify:** `flutter_app/lib/services/api_service.dart` - Add auth headers
- **Modify:** `flutter_app/lib/main.dart` - Initialize Amplify, auth navigation

---

## Task 1: Add Cognito User Pool to CDK Stack

**Files:**
- Modify: `infra/stacks/babyhealth_stack.py:1-30` (imports)
- Modify: `infra/stacks/babyhealth_stack.py:35-62` (after S3 bucket)

**Interfaces:**
- Produces: `self.user_pool: cognito.UserPool`, `self.user_pool_client: cognito.UserPoolClient`

- [ ] **Step 1: Add Cognito import to babyhealth_stack.py**

Open `infra/stacks/babyhealth_stack.py` and add to imports:

```python
from aws_cdk import (
    Duration,
    RemovalPolicy,
    Stack,
    aws_apigatewayv2 as apigwv2,
    aws_apigatewayv2_integrations as apigwv2_integrations,
    aws_apigatewayv2_authorizers as apigwv2_authorizers,  # ADD THIS
    aws_cognito as cognito,  # ADD THIS
    aws_dynamodb as dynamodb,
    aws_iam as iam,
    aws_lambda as lambda_,
    aws_logs as logs,
    aws_s3 as s3,
    CfnOutput,
)
```

- [ ] **Step 2: Add Cognito User Pool after S3 bucket section**

After the S3 bucket section (line ~62), add:

```python
        # ─── Cognito User Pool ────────────────────────────────────────────
        self.user_pool = cognito.UserPool(
            self,
            "BabyHealthUserPool",
            user_pool_name="babyhealth-users",
            self_sign_up_enabled=True,
            sign_in_aliases=cognito.SignInAliases(email=True),
            auto_verify=cognito.AutoVerifiedAttrs(email=True),
            password_policy=cognito.PasswordPolicy(
                min_length=8,
                require_lowercase=True,
                require_digits=True,
                require_uppercase=False,
                require_symbols=False,
            ),
            account_recovery=cognito.AccountRecovery.EMAIL_ONLY,
            removal_policy=RemovalPolicy.DESTROY,
        )

        # User Pool Client for Flutter app
        self.user_pool_client = self.user_pool.add_client(
            "BabyHealthAppClient",
            user_pool_client_name="babyhealth-flutter",
            auth_flows=cognito.AuthFlow(
                user_password=True,
                user_srp=True,
            ),
            generate_secret=False,  # Mobile apps don't use secrets
        )
```

- [ ] **Step 3: Verify syntax with CDK synth**

Run:
```bash
cd /Users/hectormartinez/hackathon-Kiro/infra && cdk synth --quiet 2>&1 | head -20
```
Expected: No syntax errors

- [ ] **Step 4: Commit**

```bash
cd /Users/hectormartinez/hackathon-Kiro
git add infra/stacks/babyhealth_stack.py
git commit -m "feat(infra): add Cognito User Pool and client"
```

---

## Task 2: Add Cognito Authorizer and Update Routes

**Files:**
- Modify: `infra/stacks/babyhealth_stack.py:129-165` (API Gateway section)

**Interfaces:**
- Consumes: `self.user_pool`, `self.user_pool_client`
- Produces: `self.authorizer: HttpUserPoolAuthorizer`

- [ ] **Step 1: Create Cognito Authorizer before API Gateway routes**

After the `lambda_integration` definition (around line 151), add:

```python
        # ─── Cognito Authorizer ───────────────────────────────────────────
        self.authorizer = apigwv2_authorizers.HttpUserPoolAuthorizer(
            "BabyHealthCognitoAuthorizer",
            self.user_pool,
            user_pool_clients=[self.user_pool_client],
            identity_source=["$request.header.Authorization"],
        )
```

- [ ] **Step 2: Replace existing routes with protected/public routes**

Remove the existing `add_routes` calls (proxy+ and root) and replace with:

```python
        # ─── Public Routes (no auth) ──────────────────────────────────────
        self.api.add_routes(
            path="/health",
            methods=[apigwv2.HttpMethod.GET],
            integration=lambda_integration,
        )

        # ─── Protected Routes (require JWT) ───────────────────────────────
        self.api.add_routes(
            path="/upload-url",
            methods=[apigwv2.HttpMethod.GET],
            integration=lambda_integration,
            authorizer=self.authorizer,
        )

        self.api.add_routes(
            path="/analyze",
            methods=[apigwv2.HttpMethod.POST],
            integration=lambda_integration,
            authorizer=self.authorizer,
        )
```

- [ ] **Step 3: Verify syntax with CDK synth**

Run:
```bash
cd /Users/hectormartinez/hackathon-Kiro/infra && cdk synth --quiet 2>&1 | head -20
```
Expected: No syntax errors

- [ ] **Step 4: Commit**

```bash
cd /Users/hectormartinez/hackathon-Kiro
git add infra/stacks/babyhealth_stack.py
git commit -m "feat(infra): add Cognito authorizer and protected routes"
```

---

## Task 3: Update CORS to Restrictive and Add Cognito Outputs

**Files:**
- Modify: `infra/stacks/babyhealth_stack.py:130-145` (CORS config)
- Modify: `infra/stacks/babyhealth_stack.py:177-205` (Outputs section)

**Interfaces:**
- Produces: CfnOutputs for `UserPoolId`, `UserPoolClientId`, `CognitoRegion`

- [ ] **Step 1: Update CORS to restrictive configuration**

Find the `cors_preflight` in HttpApi and update:

```python
        self.api = apigwv2.HttpApi(
            self,
            "BabyHealthHttpApi",
            api_name="babyhealth-api",
            cors_preflight=apigwv2.CorsPreflightOptions(
                allow_origins=[],  # Empty = reject browser requests
                allow_methods=[
                    apigwv2.CorsHttpMethod.GET,
                    apigwv2.CorsHttpMethod.POST,
                    apigwv2.CorsHttpMethod.PUT,
                    apigwv2.CorsHttpMethod.OPTIONS,
                ],
                allow_headers=["Authorization", "Content-Type"],
                max_age=Duration.hours(1),
            ),
        )
```

- [ ] **Step 2: Add Cognito outputs at end of stack**

After existing CfnOutputs, add:

```python
        CfnOutput(
            self,
            "UserPoolId",
            value=self.user_pool.user_pool_id,
            description="Cognito User Pool ID",
        )

        CfnOutput(
            self,
            "UserPoolClientId",
            value=self.user_pool_client.user_pool_client_id,
            description="Cognito User Pool Client ID",
        )

        CfnOutput(
            self,
            "CognitoRegion",
            value=self.region,
            description="AWS Region for Cognito",
        )
```

- [ ] **Step 3: Verify full stack with CDK synth**

Run:
```bash
cd /Users/hectormartinez/hackathon-Kiro/infra && cdk synth --quiet 2>&1 | head -30
```
Expected: No errors, outputs listed

- [ ] **Step 4: Commit**

```bash
cd /Users/hectormartinez/hackathon-Kiro
git add infra/stacks/babyhealth_stack.py
git commit -m "feat(infra): restrictive CORS and Cognito outputs"
```

---

## Task 4: Add Amplify Dependencies to Flutter

**Files:**
- Modify: `flutter_app/pubspec.yaml`

**Interfaces:**
- Produces: Amplify packages available for import

- [ ] **Step 1: Add Amplify dependencies to pubspec.yaml**

Open `flutter_app/pubspec.yaml` and update dependencies section:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6
  image_picker: ^1.0.7
  http: 1.2.2
  uuid: 4.5.1
  camera: 0.11.0+2
  path_provider: 2.1.4
  path: 1.9.0
  record: ^5.0.0
  permission_handler: ^11.0.1
  # Auth dependencies
  amplify_flutter: ^2.0.0
  amplify_auth_cognito: ^2.0.0
```

- [ ] **Step 2: Run flutter pub get**

Run:
```bash
cd /Users/hectormartinez/hackathon-Kiro/flutter_app && flutter pub get
```
Expected: Dependencies resolved successfully

- [ ] **Step 3: Commit**

```bash
cd /Users/hectormartinez/hackathon-Kiro
git add flutter_app/pubspec.yaml
git commit -m "feat(flutter): add Amplify Auth dependencies"
```

---

## Task 5: Create Amplify Configuration

**Files:**
- Create: `flutter_app/lib/config/amplify_config.dart`

**Interfaces:**
- Produces: `AmplifyConfig.configure()` function

- [ ] **Step 1: Create amplify_config.dart**

Create file `flutter_app/lib/config/amplify_config.dart`:

```dart
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// Amplify configuration for BabyHealth.
///
/// Contains Cognito User Pool settings. Values are placeholders
/// until CDK deployment provides actual IDs.
class AmplifyConfig {
  // TODO: Update these after CDK deploy
  static const String userPoolId = 'us-east-1_XXXXXXXXX';
  static const String userPoolClientId = 'XXXXXXXXXXXXXXXXXXXXXXXXXX';
  static const String region = 'us-east-1';

  /// Configures Amplify with Cognito Auth plugin.
  ///
  /// Call this once in main() before runApp().
  /// Returns true if configuration succeeded, false if already configured.
  static Future<bool> configure() async {
    if (Amplify.isConfigured) {
      return false;
    }

    try {
      final authPlugin = AmplifyAuthCognito();
      await Amplify.addPlugin(authPlugin);

      await Amplify.configure(_amplifyConfig);
      return true;
    } on AmplifyAlreadyConfiguredException {
      return false;
    }
  }

  static const String _amplifyConfig = '''
{
  "UserAgent": "aws-amplify-cli/2.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "UserAgent": "aws-amplify/cli",
        "Version": "0.1.0",
        "IdentityManager": {
          "Default": {}
        },
        "CognitoUserPool": {
          "Default": {
            "PoolId": "$userPoolId",
            "AppClientId": "$userPoolClientId",
            "Region": "$region"
          }
        },
        "Auth": {
          "Default": {
            "authenticationFlowType": "USER_SRP_AUTH",
            "usernameAttributes": ["EMAIL"],
            "signupAttributes": ["EMAIL"],
            "passwordProtectionSettings": {
              "passwordPolicyMinLength": 8,
              "passwordPolicyCharacters": []
            }
          }
        }
      }
    }
  }
}
''';
}
```

- [ ] **Step 2: Verify no syntax errors**

Run:
```bash
cd /Users/hectormartinez/hackathon-Kiro/flutter_app && flutter analyze lib/config/amplify_config.dart
```
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
cd /Users/hectormartinez/hackathon-Kiro
git add flutter_app/lib/config/amplify_config.dart
git commit -m "feat(flutter): add Amplify configuration"
```

---

## Task 6: Create Auth Service

**Files:**
- Create: `flutter_app/lib/services/auth_service.dart`

**Interfaces:**
- Produces: `AuthService` class with `signUp()`, `confirmSignUp()`, `signIn()`, `signOut()`, `isSignedIn()`, `getAccessToken()`

- [ ] **Step 1: Create auth_service.dart**

Create file `flutter_app/lib/services/auth_service.dart`:

```dart
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
```

- [ ] **Step 2: Verify no syntax errors**

Run:
```bash
cd /Users/hectormartinez/hackathon-Kiro/flutter_app && flutter analyze lib/services/auth_service.dart
```
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
cd /Users/hectormartinez/hackathon-Kiro
git add flutter_app/lib/services/auth_service.dart
git commit -m "feat(flutter): add AuthService with Cognito operations"
```

---

## Task 7: Create Login Screen

**Files:**
- Create: `flutter_app/lib/screens/login_screen.dart`

**Interfaces:**
- Consumes: `AuthService.signIn()`
- Produces: `LoginScreen` widget with navigation to signup and home

- [ ] **Step 1: Create login_screen.dart**

Create file `flutter_app/lib/screens/login_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// Login screen for BabyHealth.
///
/// Allows users to sign in with email and password.
/// Navigates to SignupScreen for new users or VerifyEmailScreen
/// if email confirmation is needed.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (result.needsConfirmation) {
      Navigator.pushNamed(
        context,
        '/verify-email',
        arguments: _emailController.text.trim(),
      );
    } else {
      setState(() => _errorMessage = result.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Title
                  Icon(
                    Icons.child_care,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'BabyHealth',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión para continuar',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 32),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu email';
                      }
                      if (!value.contains('@')) {
                        return 'Ingresa un email válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu contraseña';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Login button
                  FilledButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Iniciar Sesión'),
                  ),
                  const SizedBox(height: 16),

                  // Sign up link
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    child: const Text('¿No tienes cuenta? Regístrate'),
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

- [ ] **Step 2: Verify no syntax errors**

Run:
```bash
cd /Users/hectormartinez/hackathon-Kiro/flutter_app && flutter analyze lib/screens/login_screen.dart
```
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
cd /Users/hectormartinez/hackathon-Kiro
git add flutter_app/lib/screens/login_screen.dart
git commit -m "feat(flutter): add LoginScreen"
```

---

## Task 8: Create Signup Screen

**Files:**
- Create: `flutter_app/lib/screens/signup_screen.dart`

**Interfaces:**
- Consumes: `AuthService.signUp()`
- Produces: `SignupScreen` widget with navigation to verify-email

- [ ] **Step 1: Create signup_screen.dart**

Create file `flutter_app/lib/screens/signup_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// Signup screen for BabyHealth.
///
/// Allows new users to create an account with email and password.
/// Navigates to VerifyEmailScreen after successful signup.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success || result.needsConfirmation) {
      Navigator.pushReplacementNamed(
        context,
        '/verify-email',
        arguments: _emailController.text.trim(),
      );
    } else {
      setState(() => _errorMessage = result.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'Crea tu cuenta',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresa tus datos para registrarte',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 32),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu email';
                      }
                      if (!value.contains('@')) {
                        return 'Ingresa un email válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outlined),
                      border: OutlineInputBorder(),
                      helperText: 'Mínimo 8 caracteres con letras y números',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa una contraseña';
                      }
                      if (value.length < 8) {
                        return 'Mínimo 8 caracteres';
                      }
                      if (!value.contains(RegExp(r'[a-z]'))) {
                        return 'Debe incluir letras minúsculas';
                      }
                      if (!value.contains(RegExp(r'[0-9]'))) {
                        return 'Debe incluir números';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm password field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      prefixIcon: Icon(Icons.lock_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Signup button
                  FilledButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Crear Cuenta'),
                  ),
                  const SizedBox(height: 16),

                  // Login link
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('¿Ya tienes cuenta? Inicia sesión'),
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

- [ ] **Step 2: Verify no syntax errors**

Run:
```bash
cd /Users/hectormartinez/hackathon-Kiro/flutter_app && flutter analyze lib/screens/signup_screen.dart
```
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
cd /Users/hectormartinez/hackathon-Kiro
git add flutter_app/lib/screens/signup_screen.dart
git commit -m "feat(flutter): add SignupScreen"
```

---

## Task 9: Create Verify Email Screen

**Files:**
- Create: `flutter_app/lib/screens/verify_email_screen.dart`

**Interfaces:**
- Consumes: `AuthService.confirmSignUp()`, `AuthService.resendConfirmationCode()`
- Produces: `VerifyEmailScreen` widget with navigation to login

- [ ] **Step 1: Create verify_email_screen.dart**

Create file `flutter_app/lib/screens/verify_email_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// Email verification screen for BabyHealth.
///
/// Accepts the verification code sent to the user's email.
/// Navigates to LoginScreen after successful verification.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _authService = AuthService();

  late String _email;
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _email = ModalRoute.of(context)!.settings.arguments as String;
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final result = await _authService.confirmSignUp(
      email: _email,
      code: _codeController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verificado. Ya puedes iniciar sesión.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      setState(() => _errorMessage = result.error);
    }
  }

  Future<void> _handleResend() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final result = await _authService.resendConfirmationCode(email: _email);

    if (!mounted) return;

    setState(() => _isResending = false);

    if (result.success) {
      setState(() => _successMessage = 'Código reenviado a $_email');
    } else {
      setState(() => _errorMessage = result.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Email'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Icon(
                    Icons.mark_email_read_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),

                  // Header
                  Text(
                    'Verifica tu email',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresa el código de 6 dígitos enviado a:',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 32),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),

                  // Success message
                  if (_successMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Text(
                        _successMessage!,
                        style: TextStyle(color: Colors.green[700]),
                      ),
                    ),

                  // Code field
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      letterSpacing: 8,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Código de verificación',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    maxLength: 6,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa el código';
                      }
                      if (value.length != 6) {
                        return 'El código debe tener 6 dígitos';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Verify button
                  FilledButton(
                    onPressed: _isLoading ? null : _handleVerify,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Verificar'),
                  ),
                  const SizedBox(height: 16),

                  // Resend link
                  TextButton(
                    onPressed: _isResending ? null : _handleResend,
                    child: _isResending
                        ? const Text('Reenviando...')
                        : const Text('¿No recibiste el código? Reenviar'),
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

- [ ] **Step 2: Verify no syntax errors**

Run:
```bash
cd /Users/hectormartinez/hackathon-Kiro/flutter_app && flutter analyze lib/screens/verify_email_screen.dart
```
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
cd /Users/hectormartinez/hackathon-Kiro
git add flutter_app/lib/screens/verify_email_screen.dart
git commit -m "feat(flutter): add VerifyEmailScreen"
```

---

## Task 10: Update API Service with Auth Headers

**Files:**
- Modify: `flutter_app/lib/services/api_service.dart`

**Interfaces:**
- Consumes: `AuthService.getAccessToken()`
- Produces: Updated `ApiService` with `Authorization` header in requests

- [ ] **Step 1: Add auth_service import and _authService field**

At top of `api_service.dart`, add import:

```dart
import 'auth_service.dart';
```

Inside `ApiService` class, add field after `_baseUrl`:

```dart
  final AuthService _authService;

  ApiService({
    http.Client? client,
    String? baseUrl,
    AuthService? authService,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _authService = authService ?? AuthService();
```

- [ ] **Step 2: Add _getAuthHeaders method**

Add this method to `ApiService` class:

```dart
  /// Gets headers including Authorization if user is signed in.
  Future<Map<String, String>> _getAuthHeaders() async {
    final headers = {'Content-Type': 'application/json'};

    final token = await _authService.getAccessToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
```

- [ ] **Step 3: Update _postJson to use auth headers**

Replace the existing `_postJson` method:

```dart
  Future<Map<String, dynamic>> _postJson(
    Uri uri,
    Map<String, dynamic> body,
  ) async {
    try {
      final headers = await _getAuthHeaders();

      final response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(
            Duration(seconds: AppConfig.httpTimeoutSeconds),
          );

      if (response.statusCode == 401) {
        throw HttpException(
          'Sesión expirada. Por favor inicia sesión de nuevo.',
          uri: uri,
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Servidor respondió con código ${response.statusCode}',
          uri: uri,
        );
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } on HttpException {
      rethrow;
    }
  }
```

- [ ] **Step 4: Update getUploadUrl to use GET with auth headers**

Replace the `getUploadUrl` method to use GET request with query parameters:

```dart
  Future<Map<String, dynamic>> getUploadUrl({
    required String mediaType,
    required String contentType,
  }) async {
    final headers = await _getAuthHeaders();

    final uri = Uri.parse('$_baseUrl/upload-url').replace(
      queryParameters: {
        'media_type': mediaType,
        'content_type': contentType,
      },
    );

    try {
      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: AppConfig.httpTimeoutSeconds));

      if (response.statusCode == 401) {
        throw HttpException(
          'Sesión expirada. Por favor inicia sesión de nuevo.',
          uri: uri,
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Servidor respondió con código ${response.statusCode}',
          uri: uri,
        );
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } on HttpException {
      rethrow;
    }
  }
```

- [ ] **Step 5: Verify no syntax errors**

Run:
```bash
cd /Users/hectormartinez/hackathon-Kiro/flutter_app && flutter analyze lib/services/api_service.dart
```
Expected: No issues found

- [ ] **Step 6: Commit**

```bash
cd /Users/hectormartinez/hackathon-Kiro
git add flutter_app/lib/services/api_service.dart
git commit -m "feat(flutter): add auth headers to ApiService"
```

---

## Task 11: Update main.dart with Amplify Init and Auth Navigation

**Files:**
- Modify: `flutter_app/lib/main.dart`

**Interfaces:**
- Consumes: `AmplifyConfig.configure()`, `AuthService.isSignedIn()`
- Produces: Updated app with auth flow navigation

- [ ] **Step 1: Update imports in main.dart**

Replace imports at top:

```dart
import 'package:flutter/material.dart';

import 'config/amplify_config.dart';
import 'config/app_config.dart';
import 'screens/audio_result_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/result_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/audio_screen.dart';
import 'screens/verify_email_screen.dart';
import 'services/auth_service.dart';
```

- [ ] **Step 2: Update main() to initialize Amplify**

Replace the `main()` function:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AmplifyConfig.configure();
  runApp(const BabyHealthApp());
}
```

- [ ] **Step 3: Add AuthWrapper widget**

Add this widget after `BabyHealthApp`:

```dart
/// Wrapper that checks auth state and routes accordingly.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  bool _isLoading = true;
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final isSignedIn = await _authService.isSignedIn();
    if (mounted) {
      setState(() {
        _isSignedIn = isSignedIn;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isSignedIn) {
      return const SplashScreen();
    } else {
      return const LoginScreen();
    }
  }
}
```

- [ ] **Step 4: Update routes in BabyHealthApp**

Replace the routes map in `BabyHealthApp.build()`:

```dart
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/verify-email': (context) => const VerifyEmailScreen(),
        '/splash': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/camera': (context) => const CameraScreen(),
        '/audio': (context) => const AudioScreen(),
        '/result': (context) => const ResultScreen(),
        '/audio-result': (context) => const AudioResultScreen(),
      },
```

- [ ] **Step 5: Verify no syntax errors**

Run:
```bash
cd /Users/hectormartinez/hackathon-Kiro/flutter_app && flutter analyze lib/main.dart
```
Expected: No issues found

- [ ] **Step 6: Commit**

```bash
cd /Users/hectormartinez/hackathon-Kiro
git add flutter_app/lib/main.dart
git commit -m "feat(flutter): integrate Amplify Auth in app navigation"
```

---

## Task 12: Deploy CDK and Update Flutter Config

**Files:**
- Modify: `flutter_app/lib/config/amplify_config.dart` (update IDs from CDK output)

**Interfaces:**
- Consumes: CDK outputs (UserPoolId, UserPoolClientId)

- [ ] **Step 1: Deploy CDK stack**

Run:
```bash
cd /Users/hectormartinez/hackathon-Kiro/infra && cdk deploy --require-approval never
```
Expected: Stack deploys successfully with Cognito outputs

- [ ] **Step 2: Copy Cognito IDs from output**

Look for these outputs:
```
Outputs:
BabyHealthStack.UserPoolId = us-east-1_XXXXXXXXX
BabyHealthStack.UserPoolClientId = XXXXXXXXXXXXXXXXXXXXXXXXXX
```

- [ ] **Step 3: Update amplify_config.dart with real IDs**

Edit `flutter_app/lib/config/amplify_config.dart` and replace placeholder values:

```dart
  static const String userPoolId = 'us-east-1_ACTUAL_ID';
  static const String userPoolClientId = 'ACTUAL_CLIENT_ID';
  static const String region = 'us-east-1';
```

- [ ] **Step 4: Commit**

```bash
cd /Users/hectormartinez/hackathon-Kiro
git add flutter_app/lib/config/amplify_config.dart
git commit -m "feat(flutter): update Amplify config with deployed Cognito IDs"
```

---

## Task 13: Create Test Users in Cognito

**Files:**
- None (AWS Console or CLI operation)

- [ ] **Step 1: Create demo user via AWS CLI**

Run:
```bash
USER_POOL_ID=$(aws cloudformation describe-stacks --stack-name BabyHealthStack --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue" --output text)

aws cognito-idp admin-create-user \
  --user-pool-id $USER_POOL_ID \
  --username demo@babyhealth.app \
  --user-attributes Name=email,Value=demo@babyhealth.app Name=email_verified,Value=true \
  --temporary-password TempPass123! \
  --message-action SUPPRESS

aws cognito-idp admin-set-user-password \
  --user-pool-id $USER_POOL_ID \
  --username demo@babyhealth.app \
  --password Demo2026! \
  --permanent
```

- [ ] **Step 2: Create judge user via AWS CLI**

Run:
```bash
aws cognito-idp admin-create-user \
  --user-pool-id $USER_POOL_ID \
  --username judge@babyhealth.app \
  --user-attributes Name=email,Value=judge@babyhealth.app Name=email_verified,Value=true \
  --temporary-password TempPass123! \
  --message-action SUPPRESS

aws cognito-idp admin-set-user-password \
  --user-pool-id $USER_POOL_ID \
  --username judge@babyhealth.app \
  --password Judge2026! \
  --permanent
```

- [ ] **Step 3: Verify users exist**

Run:
```bash
aws cognito-idp list-users --user-pool-id $USER_POOL_ID --query "Users[].Username"
```
Expected: `["demo@babyhealth.app", "judge@babyhealth.app"]`

---

## Task 14: Test Full Auth Flow

**Files:**
- None (manual testing)

- [ ] **Step 1: Run Flutter app**

Run:
```bash
cd /Users/hectormartinez/hackathon-Kiro/flutter_app && flutter run
```

- [ ] **Step 2: Test login with demo user**

1. App should show LoginScreen
2. Enter: `demo@babyhealth.app` / `Demo2026!`
3. Should navigate to SplashScreen then HomeScreen

- [ ] **Step 3: Test signup flow**

1. Tap "¿No tienes cuenta? Regístrate"
2. Enter new email and password meeting requirements
3. Should navigate to VerifyEmailScreen
4. Check email for code
5. Enter code and verify

- [ ] **Step 4: Test API call with auth**

1. From HomeScreen, navigate to Camera
2. Take a photo or video
3. Submit for analysis
4. Should succeed (not get 401)

- [ ] **Step 5: Final commit**

```bash
cd /Users/hectormartinez/hackathon-Kiro
git add -A
git commit -m "feat: complete Cognito auth integration

- CDK: Cognito User Pool, Authorizer, restrictive CORS
- Flutter: Amplify Auth, Login/Signup/Verify screens
- API: Authorization headers in requests
- Test users: demo@babyhealth.app, judge@babyhealth.app"
```
