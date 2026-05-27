import 'package:cims/core/client/api_client.dart';

// Aquest cas d’ús encapsula la desactivació del compte de l’usuari autenticat.
// Manté aquesta acció separada de la pantalla i confirma l’operació amb la contrasenya actual.
class DeleteAccountUseCase {
  const DeleteAccountUseCase(this._apiClient);

  // Aquest client permet enviar la desactivació del compte al backend.
  // Això manté la pantalla desacoblada dels detalls de la petició.
  final ApiClient _apiClient;

  // Envia la contrasenya actual per confirmar la desactivació del compte.
  // Si el backend valida la contrasenya, el compte queda desactivat.
  Future<void> call({
    required String password,
  }) {
    return _apiClient.deleteAccount(
      password: password,
    );
  }
}
