import 'package:cims/core/client/api_client.dart';

// Aquest cas d’ús encapsula el restabliment de la contrasenya.
// Serveix per separar aquesta acció de la capa visual
// i delegar la comunicació amb el backend al client d’API.
class ResetPasswordUseCase {
  const ResetPasswordUseCase({required ApiClient apiClient})
      : _apiClient = apiClient;

  // Aquest bloc guarda la dependència necessària per executar
  // el canvi real de contrasenya.
  final ApiClient _apiClient;

  // Aquest mètode envia el token del procés de recuperació
  // i la nova contrasenya perquè el backend pugui validar i aplicar el canvi.
  Future<void> execute({
    required String token,
    required String newPassword,
  }) {
    return _apiClient.resetPassword(
      token: token,
      newPassword: newPassword,
    );
  }
}
