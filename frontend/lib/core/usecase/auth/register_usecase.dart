import 'package:cims/core/client/api_client.dart';

// Aquest cas d’ús encapsula l’operació de registre d’un nou usuari.
// Serveix per separar la creació del compte de la lògica visual de la pantalla.
class RegisterUseCase {
  const RegisterUseCase({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  // Aquest bloc guarda la dependència necessària per executar el registre real.
  final ApiClient _apiClient;

  // Aquest mètode envia les dades necessàries per crear un compte nou.
  // La seva funció és delegar el registre al client d’API
  // mantenint la pantalla desacoblada de la comunicació amb el backend.
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