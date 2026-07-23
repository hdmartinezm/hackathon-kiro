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
          onPressed: () => Navigator.of(context).pushReplacementNamed('/web-landing'),
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
