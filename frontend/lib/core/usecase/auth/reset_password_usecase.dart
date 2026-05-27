import 'package:cims/core/client/api_client.dart';

// Aquest cas d’ús encapsula el restabliment de la contrasenya.
// Separa aquesta acció de la pantalla i delega la comunicació amb el backend.
class ResetPasswordUseCase {
  const ResetPasswordUseCase({required ApiClient apiClient})
      : _apiClient = apiClient;

  // Aquest client permet enviar el token i la nova contrasenya al backend.
  // Això manté la pantalla desacoblada dels detalls de l’API.
  final ApiClient _apiClient;

  // Executa el canvi de contrasenya amb el token de recuperació.
  // El backend valida el token abans d’aplicar la nova contrasenya.
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
