import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_localizations.dart';
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
        SnackBar(
          content: Text(context.l10n.emailVerified),
          backgroundColor: const Color(0xFF389BB0),
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
        SnackBar(
          content: Text(context.l10n.codeResent),
          backgroundColor: const Color(0xFF389BB0),
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
                  Text(
                    context.l10n.verifyYourEmail,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B2826),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    context.l10n.codeSentTo,
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
                  if (viewModel.errorCode != null)
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
                              context.l10n.translateAuthError(
                                viewModel.errorCode!,
                                viewModel.errorDetail,
                              ),
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
                          return context.l10n.enterCode;
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
                          : Text(
                              context.l10n.verify,
                              style: const TextStyle(
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
                    child: Text(
                      context.l10n.didNotReceiveCode,
                      style: const TextStyle(color: Color(0xFF389BB0)),
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
