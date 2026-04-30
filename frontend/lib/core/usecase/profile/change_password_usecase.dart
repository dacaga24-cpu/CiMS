import 'package:cims/core/client/api_client.dart';

// Aquest cas d’ús encapsula el canvi de contrasenya de l’usuari autenticat.
// Manté la lògica separada de la pantalla i centralitza l’acció de compte.
class ChangePasswordUseCase {
  const ChangePasswordUseCase(this._apiClient);

  final ApiClient _apiClient;

  // Aquest mètode envia la contrasenya actual i la nova al backend.
  // Si el backend valida les dades correctament, l’operació finalitza sense retornar cap valor.
  Future<void> call({
    required String currentPassword,
    required String newPassword,
  }) {
    return _apiClient.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
