// Aquesta classe centralitza la configuració de connexió amb el backend.
// Permet decidir la URL base segons l’entorn sense repartir aquesta lògica pel projecte.
class ApiConfig {
  // Aquesta constant permet definir la URL del backend des de fora del codi.
  // S’utilitza per apuntar a entorns locals, de proves o alternatius.
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // Aquesta constant defineix la URL del backend de producció.
  // Actua com a valor per defecte perquè l’aplicació funcioni sense configuració addicional.
  static const String _productionBaseUrl =
      'https://cims-backend-639822259289.europe-southwest1.run.app';

  // Aquesta propietat retorna la URL base final que farà servir l’aplicació.
  // Prioritza la URL definida per entorn i, si no existeix, utilitza la de producció.
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    return _productionBaseUrl;
  }
}
