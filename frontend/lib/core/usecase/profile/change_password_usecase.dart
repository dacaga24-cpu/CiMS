import 'package:cims/core/client/api_client.dart';

// Aquest cas d’ús encapsula el canvi de contrasenya de l’usuari autenticat.
// Manté aquesta acció separada de la pantalla i centralitzada dins de la gestió del compte.
class ChangePasswordUseCase {
  const ChangePasswordUseCase(this._apiClient);

  // Aquest client permet enviar el canvi de contrasenya al backend.
  // Això manté la pantalla desacoblada dels detalls de la petició.
  final ApiClient _apiClient;

  // Envia la contrasenya actual i la nova contrasenya al backend.
  // Si la validació és correcta, l’operació finalitza sense retornar cap valor.
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
