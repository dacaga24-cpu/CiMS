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
    this.maxLength,
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

  // Límit dur de caràcters que pot escriure l'usuari. Per defecte és null
  // (sense límit). Quan s'indica, ocultem el comptador integrat de
  // Material per no contaminar visualment el camp arrodonit.
  final int? maxLength;

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
        maxLength: maxLength,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFFB0B3B8),
            fontSize: 18,
          ),
          suffixIcon: suffixIcon,
          // Amaguem el comptador automàtic perquè el camp de píndola no té
          // espai per al text inferior i el límit ja es respecta a nivell
          // d'input.
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
