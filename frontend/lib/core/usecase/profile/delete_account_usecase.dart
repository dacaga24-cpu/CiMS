import 'package:cims/core/client/api_client.dart';

// Aquest cas d’ús encapsula la desactivació del compte de l’usuari autenticat.
// Manté aquesta acció separada de la pantalla i confirma l’operació amb la contrasenya actual.
class DeleteAccountUseCase {
  const DeleteAccountUseCase(this._apiClient);

  final ApiClient _apiClient;

  // Aquest mètode envia la contrasenya actual al backend per confirmar
  // que l’usuari vol desactivar el seu propi compte.
  Future<void> call({
    required String password,
  }) {
    return _apiClient.deleteAccount(
      password: password,
    );
  }
}
