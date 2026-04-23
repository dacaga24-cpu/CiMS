import 'package:flutter/material.dart';

// Aquesta classe centralitza el tema visual global de l’aplicació.
// Permet mantenir una aparença coherent sense repetir estils
// en cada pantalla o widget del projecte.
class AppTheme {
  // Aquest tema defineix l’estil visual principal de la versió clara de l’aplicació.
  // Agrupa colors i configuracions comunes perquè els formularis i components
  // comparteixin la mateixa línia visual a tot el projecte.
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0B57D0),
        brightness: Brightness.light,
      ),

      // Aquest bloc personalitza l’aspecte general dels camps de text.
      // Això ajuda a mantenir una experiència més uniforme en pantalles
      // com el login, el registre o els filtres del catàleg.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE0E0E0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF0B57D0),
            width: 2,
          ),
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF0B57D0),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}