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
  // Permet consultar el detall d’un cim a partir del seu identificador.
  static String peakById(int peakId) => '$peaks/$peakId';

  // Aquestes rutes permeten consultar i actualitzar l’estat personal
  // que l’usuari té assignat als cims.
  static const String peakStatus = '$api/peak-status';

  // Aquesta ajuda construeix la ruta de l’estat personal d’un cim concret.
  // Es farà servir des del detall per consultar o modificar els botons d’estat.
  static String peakStatusByPeakId(int peakId) => '$peakStatus/$peakId';

  // Aquesta ruta correspon al registre i gestió d’ascensions.
  // Permet enviar al backend una nova ascensió associada a un cim concret.
  static const String ascents = '$api/ascents';

  // Aquesta ajuda construeix la ruta de les ascensions d’un cim concret.
  // Permet consultar l’historial personal de l’usuari sobre aquell cim.
  static String ascentsByPeakId(int peakId) => '$ascents/peak/$peakId';

  // Aquesta ruta correspon a les estadístiques personals de l’usuari.
  // Permet carregar el resum de progrés amb una sola petició autenticada.
  static const String stats = '$api/stats';
}
