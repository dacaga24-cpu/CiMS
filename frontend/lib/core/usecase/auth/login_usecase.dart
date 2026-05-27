import 'package:cims/core/client/api_client.dart';

// Aquest cas d’ús encapsula l’operació d’iniciar sessió.
// Separa la pantalla de la comunicació directa amb el backend.
class LoginUseCase {
  const LoginUseCase({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  // Aquest client permet enviar les credencials al backend.
  // Això manté la lògica d’autenticació fora de la capa visual.
  final ApiClient _apiClient;

  // Executa l’inici de sessió amb el correu i la contrasenya rebuts.
  // Retorna la resposta necessària per guardar la sessió si les credencials són correctes.
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
