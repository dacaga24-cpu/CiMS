import 'package:cims/core/client/api_client.dart';

// Aquest cas d’ús encapsula l’operació de registre d’un nou usuari.
// Separa la creació del compte de la lògica visual de la pantalla.
class RegisterUseCase {
  const RegisterUseCase({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  // Aquest client permet enviar les dades de registre al backend.
  // Això manté la pantalla desacoblada de la comunicació amb l’API.
  final ApiClient _apiClient;

  // Executa el registre amb les dades bàsiques del nou compte.
  // Si el backend accepta la petició, el procés de creació queda completat.
  Future<void> execute({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) {
    return _apiClient.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );
  }
}
