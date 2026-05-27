import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/user.dart';

// Aquest cas d’ús encapsula l’eliminació de la foto de perfil.
// Permet que la pantalla demani l’acció sense conèixer els detalls de l’API.
class DeleteProfilePhotoUseCase {
  const DeleteProfilePhotoUseCase(this._apiClient);

  // Aquest client permet eliminar la foto de perfil a través del backend.
  // Això manté la pantalla desacoblada dels detalls de la petició.
  final ApiClient _apiClient;

  // Elimina la foto de perfil actual de l’usuari autenticat.
  // Retorna l’usuari actualitzat perquè la interfície pugui refrescar el perfil.
  Future<User> call() {
    return _apiClient.deleteProfilePhoto();
  }
}
