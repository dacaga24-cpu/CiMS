import 'package:flutter/material.dart';

// Aquesta classe centralitza el tema visual global de l’aplicació.
// Permet mantenir una aparença coherent sense repetir estils a cada pantalla.
class AppTheme {
  // Color reservat per a accions destructives o irreversibles.
  // S’utilitza per mantenir el mateix criteri visual en eliminacions i accions sensibles.
  static const Color dangerColor = Color(0xFFE84A4A);

  // Aquest tema defineix l’estil visual principal de la versió clara.
  // Agrupa colors i configuracions comunes per donar coherència a tota l’aplicació.
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0B57D0),
        brightness: Brightness.light,
      ),

      // Aquest bloc defineix l’aspecte general dels camps de text.
      // Ajuda a mantenir una experiència uniforme en formularis i filtres.
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
