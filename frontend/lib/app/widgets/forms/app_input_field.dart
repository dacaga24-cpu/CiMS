import 'package:flutter/material.dart';

// Aquest component reutilitzable representa un camp de text amb estil de píndola.
// Serveix per mantenir coherència visual entre formularis i evitar repetir codi.
class AppInputField extends StatelessWidget {
  const AppInputField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.keyboardType,
    required this.obscureText,
    required this.onChanged,
    this.onSubmitted,
    this.suffixIcon,
    this.enabled = true,
    this.maxLength,
  });

  // Aquestes dades configuren el contingut i el comportament del camp.
  // Permeten adaptar-lo a text normal, contrasenyes o entrades específiques.
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;
  final bool enabled;

  // Aquest valor limita els caràcters que pot escriure l’usuari.
  // Quan existeix, el límit s’aplica sense mostrar el comptador visual.
  final int? maxLength;

  // Aquest mètode construeix el camp amb l’estil comú dels formularis.
  // Manté el format arrodonit i la configuració visual compartida.
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        enabled: enabled,
        maxLength: maxLength,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFFB0B3B8),
            fontSize: 18,
          ),
          suffixIcon: suffixIcon,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}