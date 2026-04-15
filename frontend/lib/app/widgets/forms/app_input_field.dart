import 'package:flutter/material.dart';

// Aquest component reutilitzable representa un camp de text amb el mateix estil visual.
// Serveix per mantenir coherència entre els camps del formulari i evitar repetir codi.
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
  });

  // Aquest bloc defineix la informació necessària per configurar el camp:
  // el text introduït, l’ajuda visual, el tipus d’entrada,
  // si el contingut s’ha d’ocultar i l’acció a executar quan canvia.
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;
  final bool enabled;

  // Aquest mètode construeix visualment el camp de text amb l’estil comú del formulari.
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
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFFB0B3B8),
            fontSize: 18,
          ),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
