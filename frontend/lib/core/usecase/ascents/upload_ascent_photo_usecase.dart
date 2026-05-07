import 'dart:typed_data';

import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/ascent_upload_photo.dart';

// Aquest cas d’ús representa la pujada d’una foto d’ascensió.
// Primer demana al backend una URL temporal i després envia la imatge directament a GCS.
class UploadAscentPhotoUseCase {
  const UploadAscentPhotoUseCase(this._apiClient);

  final ApiClient _apiClient;

  // Aquest mètode rep la imatge ja preparada pel frontend.
  // Retorna la ruta d’emmagatzematge que després s’associarà a l’ascensió.
  Future<AscentUploadPhoto> call({
    required Uint8List bytes,
    required String mimeType,
    bool isPrimary = true,
  }) async {
    final signedUpload = await _apiClient.createAscentPhotoSignedUploadUrl(
      mimeType: mimeType,
      isPrimary: isPrimary,
    );

    // Es passen els headers tal com els ha retornat el backend perquè
    // formen part de la signatura v4: el Content-Type i qualsevol
    // extensionHeader (per exemple x-goog-content-length-range) han de
    // coincidir exactament al PUT o GCS rebutja la pujada amb 403.
    await _apiClient.uploadAscentPhotoBytes(
      uploadUrl: signedUpload.uploadUrl,
      bytes: bytes,
      headers: signedUpload.requiredHeaders,
    );

    return AscentUploadPhoto(
      storagePath: signedUpload.storagePath,
      isPrimary: isPrimary,
    );
  }
}
