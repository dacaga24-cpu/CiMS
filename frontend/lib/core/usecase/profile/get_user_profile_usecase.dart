import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/user.dart';

// Aquest cas d’ús encapsula la recuperació del perfil autenticat.
// Separa la consulta del perfil de la pantalla i del controller.
class GetUserProfileUseCase {
  const GetUserProfileUseCase({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  // Aquest client permet consultar el perfil a través del backend.
  // Això manté la pantalla desacoblada dels detalls de la petició.
  final ApiClient _apiClient;

  // Recupera el perfil de l’usuari autenticat.
  // Retorna l’objecte que farà servir la resta de l’aplicació.
  Future<User> execute() {
    return _apiClient.getUserProfile();
  }
}
