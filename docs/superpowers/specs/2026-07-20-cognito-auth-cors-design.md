# BabyHealth: Autenticación con Cognito y CORS Restrictivo

**Fecha:** 2026-07-20
**Estado:** Aprobado
**Autor:** Claude + Hector Martinez

## Resumen

Implementar autenticación usando AWS Cognito User Pools con API Gateway Authorizer y restringir CORS para permitir solo apps móviles nativas.

## Requisitos

1. **Autenticación:** AWS Cognito User Pools con email + password
2. **Verificación:** Email con código de verificación
3. **Autorización:** API Gateway Cognito Authorizer (valida JWT antes de Lambda)
4. **CORS:** Restrictivo - sin orígenes de browser (solo apps nativas)

## Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │ Login Screen │  │ Signup Screen│  │ Video Analysis Screen│   │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘   │
│         │                 │                      │               │
│         └────────┬────────┘                      │               │
│                  ▼                               ▼               │
│         ┌────────────────┐              ┌───────────────┐       │
│         │ Amplify Auth   │              │ HTTP + JWT    │       │
│         │ (Cognito SDK)  │              │ Authorization │       │
│         └────────┬───────┘              └───────┬───────┘       │
└──────────────────┼──────────────────────────────┼───────────────┘
                   │                              │
                   ▼                              ▼
┌──────────────────────────┐    ┌─────────────────────────────────┐
│    COGNITO USER POOL     │    │         API GATEWAY             │
│  ┌────────────────────┐  │    │  ┌───────────────────────────┐  │
│  │ Email + Password   │  │    │  │ Cognito JWT Authorizer    │  │
│  │ Email Verification │  │    │  │ (validates token)         │  │
│  └────────────────────┘  │    │  └─────────────┬─────────────┘  │
└──────────────────────────┘    │                │                │
                                │                ▼                │
                                │  ┌───────────────────────────┐  │
                                │  │ CORS: No browser origins  │  │
                                │  └─────────────┬─────────────┘  │
                                └────────────────┼────────────────┘
                                                 │
                                                 ▼
                                ┌─────────────────────────────────┐
                                │        LAMBDA + FASTAPI         │
                                │  (recibe claims del usuario     │
                                │   en request context)           │
                                └─────────────────────────────────┘
```

## Flujos de Datos

### Flujo de Registro (Sign Up)

1. Usuario ingresa email + password en Flutter
2. Flutter → Cognito: `signUp(email, password)`
3. Cognito envía código de verificación al email
4. Usuario ingresa código en Flutter
5. Flutter → Cognito: `confirmSignUp(email, code)`
6. Usuario registrado y verificado

### Flujo de Login

1. Usuario ingresa email + password
2. Flutter → Cognito: `signIn(email, password)`
3. Cognito retorna tokens (accessToken, idToken, refreshToken)
4. Flutter almacena tokens en secure storage
5. Usuario autenticado

### Flujo de Request Autenticado

1. Flutter obtiene accessToken del storage
2. Flutter → API: `POST /analyze` con header `Authorization: Bearer <token>`
3. API Gateway → Cognito Authorizer: valida token
4. Si válido: request pasa a Lambda con claims del usuario
5. Si inválido: API Gateway retorna 401 Unauthorized

## Endpoints y Protección

| Endpoint | Auth Requerida | Razón |
|----------|----------------|-------|
| `GET /health` | No | Health check para monitoring |
| `GET /upload-url` | Sí | Genera presigned URL para S3 |
| `POST /analyze` | Sí | Consume Bedrock (costo) |

## Cambios en Infraestructura (CDK)

### Nuevos recursos en `babyhealth_stack.py`

```python
from aws_cdk import aws_cognito as cognito
from aws_cdk.aws_apigatewayv2_authorizers import HttpUserPoolAuthorizer

# 1. Cognito User Pool
user_pool = cognito.UserPool(
    self, "BabyHealthUserPool",
    user_pool_name="babyhealth-users",
    self_sign_up_enabled=True,
    sign_in_aliases=cognito.SignInAliases(email=True),
    auto_verify=cognito.AutoVerifiedAttrs(email=True),
    password_policy=cognito.PasswordPolicy(
        min_length=8,
        require_lowercase=True,
        require_digits=True,
    ),
)

# 2. User Pool Client (para Flutter)
user_pool_client = user_pool.add_client(
    "BabyHealthAppClient",
    auth_flows=cognito.AuthFlow(user_password=True, user_srp=True),
    generate_secret=False,  # Apps móviles no usan secret
)

# 3. Cognito Authorizer en API Gateway
authorizer = HttpUserPoolAuthorizer(
    "BabyHealthAuthorizer",
    user_pool,
    user_pool_clients=[user_pool_client],
)

# 4. CORS restrictivo (sin orígenes de browser)
cors_preflight = apigwv2.CorsPreflightOptions(
    allow_origins=[],  # Vacío = rechaza browsers
    allow_methods=[apigwv2.CorsHttpMethod.GET, apigwv2.CorsHttpMethod.POST, apigwv2.CorsHttpMethod.PUT, apigwv2.CorsHttpMethod.OPTIONS],
    allow_headers=["Authorization", "Content-Type"],
)
```

### Rutas protegidas vs públicas

```python
# Ruta pública (health check)
api.add_routes(
    path="/health",
    methods=[HttpMethod.GET],
    integration=lambda_integration,
    # Sin authorizer
)

# Rutas protegidas
api.add_routes(
    path="/upload-url",
    methods=[HttpMethod.GET],
    integration=lambda_integration,
    authorizer=authorizer,
)

api.add_routes(
    path="/analyze",
    methods=[HttpMethod.POST],
    integration=lambda_integration,
    authorizer=authorizer,
)
```

## Implementación Flutter

### Dependencias nuevas en `pubspec.yaml`

```yaml
dependencies:
  amplify_flutter: ^2.0.0
  amplify_auth_cognito: ^2.0.0
  flutter_secure_storage: ^9.0.0
```

### Estructura de archivos nuevos

```
flutter_app/lib/
├── config/
│   └── amplifyconfiguration.dart   # Config de Cognito
├── services/
│   └── auth_service.dart           # Wrapper de Amplify Auth
├── screens/
│   ├── login_screen.dart           # Pantalla de login
│   ├── signup_screen.dart          # Pantalla de registro
│   └── verify_email_screen.dart    # Verificación de código
└── main.dart                       # Inicializa Amplify
```

### API Service con autenticación

```dart
class ApiService {
  Future<Map<String, String>> _getAuthHeaders() async {
    final session = await Amplify.Auth.fetchAuthSession();
    final cognitoSession = session as CognitoAuthSession;
    final token = cognitoSession.userPoolTokensResult.value.accessToken.raw;

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<AnalysisResult> analyzeVideo(String videoKey) async {
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/analyze'),
      headers: headers,
      body: jsonEncode({'video_key': videoKey}),
    );
    // ...
  }
}
```

### Flujo de navegación

```
App Start
    │
    ▼
¿Usuario autenticado? ──No──▶ LoginScreen
    │                              │
   Sí                         [Login/Signup]
    │                              │
    ▼                              ▼
HomeScreen ◀───────────────────────┘
```

## Manejo de Errores

| Código/Excepción | Escenario | Acción en Flutter |
|------------------|-----------|-------------------|
| 401 | Token expirado/inválido | Refresh token o redirigir a login |
| 403 | Usuario no verificado | Mostrar pantalla de verificación |
| `UserNotConfirmedException` | Email no verificado | Ir a verify_email_screen |
| `NotAuthorizedException` | Credenciales incorrectas | Mostrar error en UI |
| `UsernameExistsException` | Email ya registrado | Sugerir login |

### Refresh Token

Amplify maneja refresh automáticamente:
- Si el accessToken expira, usa refreshToken
- Si refreshToken expira (30 días), redirige a login

## Testing

### Backend (pytest)

```python
def test_analyze_without_token_returns_401():
    response = client.post("/analyze", json={"video_key": "test"})
    assert response.status_code == 401

def test_health_no_auth_required():
    response = client.get("/health")
    assert response.status_code == 200
```

### Flutter (widget tests)

- Verificar que LoginScreen muestra campos email/password
- Verificar navegación a SignupScreen
- Verificar manejo de errores en UI

## Usuarios de Prueba

Crear manualmente en Cognito para los jueces:

| Email | Password |
|-------|----------|
| demo@babyhealth.app | Demo2026! |
| judge@babyhealth.app | Judge2026! |

## Outputs CDK Nuevos

```python
CfnOutput(self, "UserPoolId", value=user_pool.user_pool_id)
CfnOutput(self, "UserPoolClientId", value=user_pool_client.user_pool_client_id)
CfnOutput(self, "CognitoRegion", value=self.region)
```

## Checklist de Implementación

- [ ] Agregar Cognito User Pool al CDK stack
- [ ] Agregar User Pool Client al CDK stack
- [ ] Crear Cognito Authorizer para API Gateway
- [ ] Configurar rutas protegidas con authorizer
- [ ] Actualizar CORS a restrictivo
- [ ] Agregar outputs de Cognito
- [ ] Agregar dependencias Amplify a Flutter
- [ ] Crear amplifyconfiguration.dart
- [ ] Implementar AuthService en Flutter
- [ ] Crear LoginScreen
- [ ] Crear SignupScreen
- [ ] Crear VerifyEmailScreen
- [ ] Actualizar ApiService con headers de auth
- [ ] Actualizar navegación en main.dart
- [ ] Crear usuarios de prueba en Cognito
- [ ] Escribir tests básicos
