// app.dart
// Responsabilidad: Configuración del MaterialApp — rutas nombradas y tema global.
// La ruta inicial es login_screen si no hay sesión activa.
// NO contiene lógica de negocio.

import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/peaks/peak_list_screen.dart';
import 'screens/peaks/peak_detail_screen.dart';
import 'screens/peaks/peak_map_screen.dart';
import 'screens/ascents/ascent_form_screen.dart';
import 'screens/ascents/ascent_history_screen.dart';
import 'screens/stats/stats_screen.dart';
import 'screens/profile/profile_screen.dart';

class CimsApp extends StatelessWidget {
  const CimsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CiMS',
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/peaks': (_) => const PeakListScreen(),
        '/peak-detail': (_) => const PeakDetailScreen(),
        '/peak-map': (_) => const PeakMapScreen(),
        '/ascent-form': (_) => const AscentFormScreen(),
        '/ascent-history': (_) => const AscentHistoryScreen(),
        '/stats': (_) => const StatsScreen(),
        '/profile': (_) => const ProfileScreen(),
      },
    );
  }
}
