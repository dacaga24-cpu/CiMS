import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/ascent.dart';
import 'package:cims/core/entity/ascent_upload_photo.dart';

// Aquest cas d’ús representa l’acció de registrar una nova ascensió.
// Centralitza aquesta operació perquè la pantalla no hagi de parlar directament amb l’API.
class RegisterAscentUseCase {
  const RegisterAscentUseCase(this._apiClient);

  final ApiClient _apiClient;

  // Aquest mètode envia les dades de l’ascensió al backend.
  // El backend identifica l’usuari amb el token guardat a la sessió.
  // Si hi ha fotos pujades, també envia les seves rutes perquè quedin associades al registre.
  Future<Ascent> call({
    required int peakId,
    required DateTime? ascentDate,
    String? notes,
    List<AscentUploadPhoto> photos = const [],
  }) {
    return _apiClient.createAscent(
      peakId: peakId,
      ascentDate: ascentDate,
      notes: notes,
      photos: photos,
    );
  }
}
