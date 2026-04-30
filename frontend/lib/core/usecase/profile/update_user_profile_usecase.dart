import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/user.dart';

// Aquest cas d’ús encapsula l’actualització de les dades bàsiques del perfil.
// Permet que el controller demani el canvi sense conèixer els detalls de l’API.
class UpdateUserProfileUseCase {
  const UpdateUserProfileUseCase(this._apiClient);

  final ApiClient _apiClient;

  // Aquest mètode envia el nom i cognoms actualitzats al backend.
  // Retorna l’usuari actualitzat per refrescar la pantalla de perfil.
  Future<User> call({
    required String firstName,
    required String lastName,
  }) {
    return _apiClient.updateUserProfile(
      firstName: firstName,
      lastName: lastName,
    );
  }
}
