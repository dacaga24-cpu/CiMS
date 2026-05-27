import 'dart:typed_data';

import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/ascent_upload_photo.dart';

// Aquest cas d’ús prepara i puja una foto d’ascensió.
// Retorna la ruta que després s’associarà al registre final.
class UploadAscentPhotoUseCase {
  const UploadAscentPhotoUseCase(this._apiClient);

  // Aquest client permet preparar la pujada i enviar la imatge al bucket.
  // Això manté la pantalla separada dels detalls d’emmagatzematge.
  final ApiClient _apiClient;

  // Puja la imatge a l’emmagatzematge i retorna les dades necessàries per associar-la.
  // També permet indicar si serà foto principal o evidència d’una verificació.
  Future<AscentUploadPhoto> call({
    required Uint8List bytes,
    required String mimeType,
    bool isPrimary = true,
    bool isVerificationEvidence = false,
  }) async {
    final signedUpload = await _apiClient.createAscentPhotoSignedUploadUrl(
      mimeType: mimeType,
      isPrimary: isPrimary,
    );

    await _apiClient.uploadAscentPhotoBytes(
      uploadUrl: signedUpload.uploadUrl,
      bytes: bytes,
      headers: signedUpload.requiredHeaders,
    );

    return AscentUploadPhoto(
      storagePath: signedUpload.storagePath,
      isPrimary: isPrimary,
      isVerificationEvidence: isVerificationEvidence,
    );
  }
}
