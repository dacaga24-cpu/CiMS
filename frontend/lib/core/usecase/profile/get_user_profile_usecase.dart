import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/user.dart';

// Aquest cas d’ús encapsula la recuperació del perfil autenticat.
// Serveix per separar la lògica de negoci de la pantalla i del controller.
class GetUserProfileUseCase {
  const GetUserProfileUseCase({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  // Aquest bloc guarda la dependència necessària per consultar
  // el perfil real de l’usuari autenticat.
  final ApiClient _apiClient;

  // Aquest mètode recupera el perfil de l’usuari des del backend
  // i retorna l’objecte que després farà servir la resta de l’aplicació.
  Future<User> execute() {
    return _apiClient.getUserProfile();
  }
}