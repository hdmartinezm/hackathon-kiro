import 'package:amplify_flutter/amplify_flutter.dart' show AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_config.dart';
import '../core/app_localizations.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/babyhealth_logo_widget.dart';
import '../widgets/settings_controls.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // If there's already an active session, skip auth and go straight home.
      final viewModel = context.read<AuthViewModel>();
      await viewModel.checkAuthStatus();
      if (!mounted) return;
      if (viewModel.state == AuthState.authenticated) {
        Navigator.of(context).pushReplacementNamed('/home');
        return;
      }

      // Otherwise, check if we should open the signup tab.
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

  Future<void> _handleSocialLogin(AuthProvider provider) async {
    // Google and Facebook are configured as Cognito federated providers.
    // Apple still requires its own OAuth app + Cognito setup.
    final isReady = ApiConfig.socialLoginEnabled &&
        (provider == AuthProvider.google ||
            provider == AuthProvider.facebook);

    if (!isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.socialComingSoon),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final viewModel = context.read<AuthViewModel>();
    viewModel.clearError();
    final success = await viewModel.loginWithProvider(provider);
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  /// Multi-color "G" for the Google button rendered with a gradient shader.
  Widget _googleIcon() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(0xFF4285F4),
          Color(0xFF34A853),
          Color(0xFFFBBC05),
          Color(0xFFEA4335),
        ],
      ).createShader(bounds),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/web-landing'),
        ),
        actions: const [
          SettingsControls(),
          SizedBox(width: 8),
        ],
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
                  // Logo - clickable to go back to landing
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pushReplacementNamed('/web-landing'),
                      child: Column(
                        children: [
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Social login buttons
                  _buildSocialButton(
                    label: context.l10n.continueWithGoogle,
                    icon: _googleIcon(),
                    onTap: () => _handleSocialLogin(AuthProvider.google),
                  ),
                  const SizedBox(height: 12),
                  _buildSocialButton(
                    label: context.l10n.continueWithApple,
                    icon: Icon(Icons.apple,
                        size: 22,
                        color: Theme.of(context).colorScheme.onSurface),
                    onTap: () => _handleSocialLogin(AuthProvider.apple),
                  ),
                  const SizedBox(height: 12),
                  _buildSocialButton(
                    label: context.l10n.continueWithFacebook,
                    icon: const Icon(Icons.facebook,
                        size: 22, color: Color(0xFF1877F2)),
                    onTap: () => _handleSocialLogin(AuthProvider.facebook),
                  ),
                  const SizedBox(height: 20),

                  // "o" divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          context.l10n.orDivider,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 20),

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
                      tabs: [
                        Tab(text: context.l10n.tabLogin),
                        Tab(text: context.l10n.tabSignup),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  Consumer<AuthViewModel>(
                    builder: (context, vm, _) {
                      if (vm.errorCode == null) return const SizedBox.shrink();
                      final errorMessage = context.l10n.translateAuthError(
                        vm.errorCode!,
                        vm.errorDetail,
                      );
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
                                errorMessage,
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
            label: context.l10n.email,
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            validator: emailValidator(context),
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: context.l10n.password,
            controller: _loginPasswordController,
            obscureText: _obscureLoginPassword,
            validator: (v) => v?.isEmpty == true ? context.l10n.fieldRequired : null,
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
                      : Text(
                          context.l10n.signIn,
                          style: const TextStyle(
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
            child: Text(
              context.l10n.noAccountSignup,
              style: const TextStyle(color: Color(0xFF389BB0)),
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
            label: context.l10n.email,
            controller: _signupEmailController,
            keyboardType: TextInputType.emailAddress,
            validator: emailValidator(context),
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: context.l10n.password,
            controller: _signupPasswordController,
            obscureText: _obscureSignupPassword,
            validator: passwordValidator(context),
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
            label: context.l10n.confirmPassword,
            controller: _signupConfirmPasswordController,
            obscureText: _obscureConfirmPassword,
            validator: (v) {
              if (v?.isEmpty == true) return context.l10n.fieldRequired;
              if (v != _signupPasswordController.text) {
                return context.l10n.passwordsDoNotMatch;
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
                      : Text(
                          context.l10n.createAccount,
                          style: const TextStyle(
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
