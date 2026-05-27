import 'dart:typed_data';

import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/user.dart';

// Aquest cas d’ús encapsula la pujada d’una foto de perfil.
// Coordina la URL temporal, la pujada de la imatge i la confirmació final al backend.
class UploadProfilePhotoUseCase {
  const UploadProfilePhotoUseCase(this._apiClient);

  // Aquest client permet preparar la pujada i actualitzar el perfil al backend.
  // Això manté la pantalla desacoblada dels detalls d’emmagatzematge.
  final ApiClient _apiClient;

  // Rep la imatge ja preparada pel frontend i completa el canvi de foto.
  // Retorna l’usuari actualitzat perquè la pantalla pugui refrescar el perfil.
  Future<User> call({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final signedUpload = await _apiClient.createProfilePhotoSignedUploadUrl(
      mimeType: mimeType,
    );

    // Els headers formen part de la pujada autoritzada.
    // S’envien tal com els retorna el backend perquè l’emmagatzematge accepti la imatge.
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
