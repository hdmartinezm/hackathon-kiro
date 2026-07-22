# Web Landing Auth Integration with Cognito

**Date:** 2026-07-22
**Status:** Approved
**Author:** Claude Code + Hector Martinez

## Summary

Add authentication functionality to the BabyHealth web landing page using AWS Amplify Flutter SDK with the existing Cognito User Pool. This includes functional navigation buttons, smooth scrolling, and a dedicated auth page with login/signup flows.

## Goals

1. Make landing page buttons functional (currently no-op)
2. Add smooth scroll navigation for section links
3. Create auth page (`/auth`) with Login/Signup tabs
4. Integrate with existing Cognito User Pool via Amplify
5. Redirect authenticated users to HomeScreen
6. Include JWT tokens in API calls for protected routes

## Non-Goals

- Social login (Google, Facebook, etc.)
- MFA configuration (can be added later)
- Password reset flow (out of scope for MVP)
- Mobile app auth (separate implementation)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Web Landing Page                            │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────────┐ │
│  │ Nav: Scroll │  │ "Solicitar   │  │ CTA: "Crear cuenta →"   │ │
│  │ to sections │  │  acceso →"   │  │                         │ │
│  └─────────────┘  └──────┬───────┘  └───────────┬─────────────┘ │
└──────────────────────────┼──────────────────────┼───────────────┘
                           │                      │
                           ▼                      ▼
                    ┌──────────────────────────────┐
                    │      /auth (AuthScreen)      │
                    │  ┌─────────┐  ┌───────────┐  │
                    │  │  Login  │  │  Signup   │  │
                    │  │   Tab   │  │    Tab    │  │
                    └───────┼─────────────┼────────┘
                            │             │
                            ▼             ▼
                    ┌──────────────────────────────┐
                    │     AuthService (Amplify)    │
                    │  - signIn()                  │
                    │  - signUp()                  │
                    │  - confirmSignUp()           │
                    │  - signOut()                 │
                    │  - getCurrentUser()          │
                    └──────────────┬───────────────┘
                                   │
                                   ▼
                    ┌──────────────────────────────┐
                    │   AWS Cognito User Pool      │
                    │   (deployed via CDK)         │
                    └──────────────────────────────┘
                                   │
                            ┌──────┴──────┐
                            ▼             ▼
                     ┌───────────┐  ┌───────────┐
                     │ HomeScreen│  │ Protected │
                     │ (with JWT)│  │ API calls │
                     └───────────┘  └───────────┘
```

## File Structure

```
frontend/lib/
├── main.dart                          # Add /auth and /verify-email routes
├── core/
│   └── amplify_config.dart            # [NEW] Amplify configuration
├── services/
│   └── auth_service.dart              # [NEW] Amplify Auth wrapper
├── viewmodels/
│   └── auth_viewmodel.dart            # [NEW] Auth state management
├── views/
│   ├── web_landing_screen.dart        # [MODIFY] Buttons + smooth scroll
│   ├── auth_screen.dart               # [NEW] Login/Signup tabs page
│   └── verify_email_screen.dart       # [NEW] Email code confirmation
└── widgets/
    └── auth_form_widget.dart          # [NEW] Reusable form widgets
```

**New files:** 5
**Modified files:** 2 (`main.dart`, `web_landing_screen.dart`)

## Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  amplify_flutter: ^2.0.0
  amplify_auth_cognito: ^2.0.0
```

## UI Screens

### AuthScreen (`/auth`)

- Two tabs: "Ingresar" (Login) and "Registrarse" (Signup)
- Email and password fields with validation
- Loading states during API calls
- Error messages displayed inline
- "Volver" button to return to landing
- Same visual style as landing (primary: `#389BB0`, bg: `#FAF7F4`)

### VerifyEmailScreen (`/verify-email`)

- 6-digit code input
- "Verificar" button
- "Reenviar código" link
- Displays email address being verified

## AuthService API

```dart
class AuthService {
  // Initialization
  Future<void> configure() async;

  // Authentication
  Future<AuthResult> signIn(String email, String password);
  Future<AuthResult> signUp(String email, String password);
  Future<AuthResult> confirmSignUp(String email, String code);
  Future<void> resendConfirmationCode(String email);
  Future<void> signOut();

  // State
  Future<AuthUser?> getCurrentUser();
  Stream<AuthState> get authStateChanges;

  // Tokens (for API calls)
  Future<String?> getAccessToken();
}

enum AuthState { unknown, authenticated, unauthenticated }

class AuthResult {
  final bool isSuccess;
  final String? error;
  final bool needsConfirmation;
}
```

## AuthViewModel

```dart
class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;

  AuthState state = AuthState.unknown;
  bool isLoading = false;
  String? errorMessage;
  String? pendingEmail; // for verification flow

  Future<void> login(String email, String password);
  Future<void> register(String email, String password);
  Future<void> verifyCode(String email, String code);
  Future<void> resendCode(String email);
  Future<void> logout();
  Future<void> checkAuthStatus();
}
```

## Button Functionality

### Navigation to Auth

| Button | Location | Action |
|--------|----------|--------|
| "Solicitar acceso →" | NavBar | `Navigator.pushNamed(context, '/auth')` |
| "Solicitar acceso →" | Hero | `Navigator.pushNamed(context, '/auth')` |
| "Crear cuenta →" | CTA Section | `Navigator.pushNamed(context, '/auth', arguments: 'signup')` |

### Smooth Scroll Navigation

| Nav Link | Target Section |
|----------|----------------|
| "Cómo funciona" | `_ComoFuncionaSection` |
| "Características" | `_CaracteristicasSection` |
| "Arquitectura" | `_ArquitecturaSection` |
| "Seguridad" | `_SeguridadSection` |

Implementation using `GlobalKey` and `Scrollable.ensureVisible()` with 500ms animation.

## User Flows

### Login Flow
```
/auth (Login tab) → Enter credentials → Submit
    ↓ Success
/home (HomeScreen with JWT)
    ↓ Error
Show error message, stay on /auth
```

### Signup Flow
```
/auth (Signup tab) → Enter email/password → Submit
    ↓ Success (needsConfirmation: true)
/verify-email → Enter 6-digit code → Submit
    ↓ Success
/home (HomeScreen with JWT)
```

## HttpClient Integration

Modify existing `http_client.dart` to include JWT:

```dart
class HttpClient {
  final AuthService _authService;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
```

## Amplify Configuration

Values from CDK outputs (`infra/stacks/babyhealth_stack.py`):

```dart
// core/amplify_config.dart
const amplifyConfig = '''{
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "UserAgent": "aws-amplify-cli/0.1.0",
        "Version": "0.1.0",
        "CognitoUserPool": {
          "Default": {
            "PoolId": "<from CDK UserPoolId output>",
            "AppClientId": "<from CDK UserPoolClientId output>",
            "Region": "<from CDK CognitoRegion output>"
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

## CTA Section Update

Replace email form with registration button:

**Before:**
- Email input + "Notificarme →" button
- Local state only

**After:**
- "Crear cuenta gratis →" button
- Navigates to `/auth` with `arguments: 'signup'`
- Subtitle: "Comienza a usar BabyHealth hoy"

## Error Handling

| Error | User Message |
|-------|--------------|
| Invalid credentials | "Email o contraseña incorrectos" |
| User not found | "No existe una cuenta con este email" |
| User already exists | "Ya existe una cuenta con este email" |
| Invalid code | "Código incorrecto. Intenta de nuevo." |
| Network error | "Error de conexión. Verifica tu internet." |
| Generic error | "Algo salió mal. Intenta de nuevo." |

## Testing Strategy

1. **Unit tests:** AuthService methods with mocked Amplify
2. **Widget tests:** AuthScreen form validation and state changes
3. **Integration test:** Full signup → verify → login flow (manual)

## Security Considerations

- Passwords validated client-side (8+ chars, lowercase, digit)
- Tokens stored securely by Amplify SDK
- HTTPS enforced for all API calls
- No sensitive data logged

## Out of Scope (Future Enhancements)

- Password reset / forgot password flow
- Social login providers
- Remember me / persistent sessions
- Account deletion
- Profile management
