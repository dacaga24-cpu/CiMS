import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/user.dart';

// Aquest cas d’ús encapsula l’eliminació de la foto de perfil.
// Permet que la pantalla demani l’acció sense conèixer els detalls de l’API.
class DeleteProfilePhotoUseCase {
  const DeleteProfilePhotoUseCase(this._apiClient);

  final ApiClient _apiClient;

  // Aquest mètode elimina la foto actual i retorna l’usuari actualitzat.
  Future<User> call() {
    return _apiClient.deleteProfilePhoto();
  }
}
