import 'dart:typed_data';

import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/user.dart';

// Aquest cas d’ús encapsula la pujada d’una foto de perfil.
// Primer demana una URL temporal, després puja la imatge i finalment confirma el canvi al backend.
class UploadProfilePhotoUseCase {
  const UploadProfilePhotoUseCase(this._apiClient);

  final ApiClient _apiClient;

  // Aquest mètode rep la imatge ja preparada pel frontend.
  // Retorna l’usuari actualitzat amb la nova foto de perfil.
  Future<User> call({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final signedUpload = await _apiClient.createProfilePhotoSignedUploadUrl(
      mimeType: mimeType,
    );

    // Els headers s’envien exactament tal com els retorna el backend.
    // Formen part de la signatura temporal i han de coincidir perquè GCS accepti la pujada.
    await _apiClient.uploadProfilePhotoBytes(
      uploadUrl: signedUpload.uploadUrl,
      bytes: bytes,
      headers: signedUpload.requiredHeaders,
    );

    return _apiClient.setProfilePhoto(
      storagePath: signedUpload.storagePath,
    );
  }
}
