import 'package:flutter/material.dart';

import '../core/app_localizations.dart';

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

/// Email validator factory that uses localization.
String? Function(String?) emailValidator(BuildContext context) {
  final l10n = context.l10n;
  return (String? value) {
    if (value == null || value.trim().isEmpty) {
      return l10n.emailRequired;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return l10n.emailInvalid;
    }
    return null;
  };
}

/// Password validator factory that uses localization (min 8 chars, 1 lowercase, 1 digit).
String? Function(String?) passwordValidator(BuildContext context) {
  final l10n = context.l10n;
  return (String? value) {
    if (value == null || value.isEmpty) {
      return l10n.passwordRequired;
    }
    if (value.length < 8) {
      return l10n.passwordMinLength;
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return l10n.passwordNeedsLowercase;
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return l10n.passwordNeedsNumber;
    }
    return null;
  };
}
