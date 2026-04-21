// Aquesta classe centralitza els camins dels endpoints del backend.
// La seva funció és evitar rutes duplicades o escrites manualment
// en diferents punts del client API.
class ApiEndpoints {
  // Aquest prefix agrupa totes les rutes exposades per l’API del backend.
  static const String api = '/api';

  // Aquest prefix agrupa les operacions relacionades amb autenticació.
  static const String auth = '$api/auth';

  // Aquest bloc defineix les rutes concretes que fa servir el frontend
  // per comunicar-se amb les funcionalitats d’autenticació i perfil.
  static const String register = '$auth/register';
  static const String login = '$auth/login';
  static const String profile = '$auth/profile';
}