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

  // Aquestes rutes corresponen al flux de recuperació de contrasenya.
  // Permeten iniciar la sol·licitud de canvi i enviar la nova contrasenya al backend.
  static const String forgotPassword = '$auth/forgot-password';
  static const String resetPassword = '$auth/reset-password';

  // Aquestes rutes corresponen al catàleg públic de cims i comarques.
  // Permeten carregar el llistat principal i deixar preparats futurs filtres.
  static const String peaks = '$api/peaks';
  static const String regions = '$api/regions';

  // Aquesta ajuda construeix la ruta d’un cim concret.
  // Encara que el detall complet arribi més endavant, el camí ja queda centralitzat.
  static String peakById(int peakId) => '$peaks/$peakId';
}
