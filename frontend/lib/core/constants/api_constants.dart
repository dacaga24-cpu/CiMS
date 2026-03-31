// api_constants.dart
// Responsabilidad: Definir la URL base de la API y las constantes de cada endpoint.
// NO contiene lógica — solo constantes estáticas.

class ApiConstants {
  // URL base de la API — rellenar con la IP/dominio del backend
  static const String baseUrl = '';

  // Auth endpoints
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String logout = '/api/auth/logout';
  static const String forgotPassword = '/api/auth/forgot-password';

  // Peak endpoints
  static const String peaks = '/api/peaks';
  static const String peakById = '/api/peaks/'; // + id
  static const String peaksByRegion = '/api/peaks/region/'; // + regionId
  static const String peaksByAltitude = '/api/peaks/altitude';
  static const String peaksSearch = '/api/peaks/search';

  // Ascent endpoints
  static const String ascents = '/api/ascents';
  static const String ascentById = '/api/ascents/'; // + id
  static const String ascentsByUser = '/api/ascents/user/'; // + userId
  static const String ascentsByPeak = '/api/ascents/peak/'; // + peakId
}
