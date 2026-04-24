import 'package:cims/core/entity/user.dart';

// Aquest contracte agrupa les operacions relacionades amb el perfil d’usuari.
abstract class ProfileApiClient {
  // Aquest mètode recupera la informació del perfil de l’usuari
  // que té la sessió iniciada a l’aplicació.
  Future<User> getUserProfile();
}
