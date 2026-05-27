import 'package:cims/core/client/api_client.dart';

// Aquest cas d’ús encapsula la sol·licitud de recuperació de contrasenya.
// Separa aquesta operació de la pantalla i delega la comunicació amb el backend.
class RequestPasswordResetUseCase {
  const RequestPasswordResetUseCase({required ApiClient apiClient})
      : _apiClient = apiClient;

  // Aquest client permet enviar la petició de recuperació al backend.
  // Això manté la pantalla desacoblada dels detalls de l’API.
  final ApiClient _apiClient;

  // Inicia el procés de recuperació de contrasenya amb el correu de l’usuari.
  // Retorna el missatge de confirmació que es mostrarà a la interfície.
  Future<String> execute({
    required String email,
  }) {
    return _apiClient.requestPasswordReset(email: email);
  }
}
