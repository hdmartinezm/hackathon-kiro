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
