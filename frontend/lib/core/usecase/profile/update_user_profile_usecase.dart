import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/user.dart';

// Aquest cas d’ús encapsula l’actualització de les dades bàsiques del perfil.
// Permet que el controller demani el canvi sense conèixer els detalls de l’API.
class UpdateUserProfileUseCase {
  const UpdateUserProfileUseCase(this._apiClient);

  // Aquest client permet actualitzar el perfil a través del backend.
  // Això manté el controller desacoblat dels detalls de la petició.
  final ApiClient _apiClient;

  // Envia el nom i els cognoms actualitzats al backend.
  // Retorna l’usuari actualitzat perquè la pantalla pugui refrescar les dades del perfil.
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
