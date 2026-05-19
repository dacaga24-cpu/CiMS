import 'package:cims/core/client/api_client.dart';

// Aquest cas d’ús encapsula l’operació d’iniciar sessió.
// La seva funció és separar la lògica de negoci de la capa de presentació
// i delegar la comunicació amb el backend al client d’API.
class LoginUseCase {
  const LoginUseCase({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  // Aquest bloc guarda la dependència necessària per executar el login real.
  final ApiClient _apiClient;

  // Aquest mètode executa l’autenticació amb les credencials rebudes
  // i retorna la resposta del backend si el procés és correcte.
  Future<LoginResponse> execute({
    required String email,
    required String password,
  }) {
    return _apiClient.login(
      email: email,
      password: password,
    );
  }
}
