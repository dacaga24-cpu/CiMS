// lib/app/config/api_config.dart

import 'package:flutter/foundation.dart';

// Aquesta classe centralitza la configuració de la connexió amb el backend.
// La seva funció és decidir quina URL base s’ha d’utilitzar segons l’entorn
// sense repartir aquesta lògica per diferents fitxers del projecte.
class ApiConfig {
  // Aquesta constant permet definir l’URL del backend des de fora del codi
  // quan es compila o s’executa l’aplicació.
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // Aquesta propietat exposa l’adreça base final que farà servir l’aplicació.
  // Primer prioritza la configuració passada per entorn i, si no existeix,
  // utilitza una configuració local útil per desenvolupament.
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000';
      default:
        return 'http://localhost:3000';
    }
  }
}