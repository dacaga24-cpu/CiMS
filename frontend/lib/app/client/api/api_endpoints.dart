// Aquesta classe centralitza les rutes del backend utilitzades pel frontend.
// Evita duplicar textos d’endpoint i facilita mantenir la comunicació amb l’API.
class ApiEndpoints {
  // Prefix comú de totes les rutes del backend.
  static const String api = '/api';

  // Rutes relacionades amb autenticació i sessió d’usuari.
  static const String auth = '$api/auth';
  static const String register = '$auth/register';
  static const String login = '$auth/login';
  static const String profile = '$auth/profile';

  // Rutes del flux de recuperació de contrasenya.
  // Permeten sol·licitar el canvi i confirmar la nova contrasenya.
  static const String forgotPassword = '$auth/forgot-password';
  static const String resetPassword = '$auth/reset-password';

  // Rutes del catàleg de cims i comarques.
  // Permeten carregar la informació principal que es mostra al llistat i als filtres.
  static const String peaks = '$api/peaks';
  static const String regions = '$api/regions';

  // Ruta específica per obtenir els cims preparats per mostrar-se al mapa.
  static const String peaksMap = '$peaks/map';

  // Construeix la ruta del detall d’un cim concret.
  static String peakById(int peakId) => '$peaks/$peakId';

  // Rutes de l’estat personal dels cims.
  // Permeten consultar i modificar si un cim és assolit, objectiu o favorit.
  static const String peakStatus = '$api/peak-status';

  // Construeix la ruta de l’estat personal d’un cim concret.
  static String peakStatusByPeakId(int peakId) => '$peakStatus/$peakId';

  // Rutes de registre i gestió d’ascensions.
  // Permeten crear, consultar, actualitzar i eliminar ascensions de l’usuari.
  static const String ascents = '$api/ascents';

  // Ruta per crear una ascensió verificada.
  // Utilitza una foto feta des de l’app i la ubicació capturada pel dispositiu.
  static const String verifiedAscent = '$ascents/verified';

  // Construeix la ruta de l’historial d’ascensions d’un cim concret.
  static String ascentsByPeakId(int peakId) => '$ascents/peak/$peakId';

  // Construeix la ruta d’una ascensió concreta.
  static String ascentById(int ascentId) => '$ascents/$ascentId';

  // Construeix la ruta de les fotos associades a una ascensió concreta.
  static String ascentPhotosByAscentId(int ascentId) =>
      '$ascents/$ascentId/photos';

  // Ruta de les estadístiques personals de l’usuari.
  static const String stats = '$api/stats';

  // Rutes relacionades amb el compte de l’usuari.
  static const String users = '$api/users';
  static const String userProfile = '$users/profile';
  static const String changePassword = '$users/password';
  static const String deleteAccount = '$users/account';

  // Rutes per gestionar la foto de perfil.
  // La imatge es puja amb una URL temporal i després queda associada al perfil.
  static const String profilePhoto = '$users/profile-photo';
  static const String profilePhotoSignedUploadUrl =
      '$profilePhoto/signed-upload-url';

  // Ruta del dashboard principal.
  // Retorna informació resumida sobre progrés, reptes i cims destacats.
  static const String dashboard = '$api/dashboard';

  // Rutes del repte mensual.
  // Permeten consultar el repte actiu i el progrés calculat per l’usuari.
  static const String monthlyChallenges = '$api/monthly-challenges';
  static const String currentMonthlyChallenge = '$monthlyChallenges/current';

  // Rutes per preparar, consultar i eliminar fotos d’ascensions.
  static const String ascentPhotos = '$api/ascent-photos';
  static const String ascentPhotosGallery = '$ascentPhotos/me';
  static const String ascentPhotoSignedUploadUrl =
      '$ascentPhotos/signed-upload-url';

  // Construeix la ruta d’una foto concreta d’ascensió.
  static String ascentPhotoById(int photoId) => '$ascentPhotos/$photoId';

  // Construeix la ruta de la previsió diària d’un cim.
  static String peakWeatherDaily(int peakId) =>
      '${peakById(peakId)}/weather/daily';

  // Construeix la ruta de la previsió horària d’un cim.
  static String peakWeatherHourly(int peakId) =>
      '${peakById(peakId)}/weather/hourly';
}