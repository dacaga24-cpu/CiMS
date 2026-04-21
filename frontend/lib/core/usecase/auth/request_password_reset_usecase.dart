import 'package:cims/core/client/api_client.dart';

// Aquest cas d’ús encapsula la sol·licitud de recuperació de contrasenya.
// Serveix per separar aquesta operació de la capa visual
// i delegar la comunicació amb el backend al client d’API.
class RequestPasswordResetUseCase {
  const RequestPasswordResetUseCase({required ApiClient apiClient})
      : _apiClient = apiClient;

  // Aquest bloc guarda la dependència necessària per executar
  // la petició real de recuperació de contrasenya.
  final ApiClient _apiClient;

  // Aquest mètode envia el correu de l’usuari al backend
  // per iniciar el procés de restabliment de contrasenya.
  Future<String> execute({
    required String email,
  }) {
    return _apiClient.requestPasswordReset(email: email);
  }
}