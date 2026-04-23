import 'package:cims/core/entity/user.dart';

// Aquest contracte agrupa les operacions relacionades amb el perfil d’usuari.
abstract class ProfileApiClient {
  Future<User> getUserProfile();
}
