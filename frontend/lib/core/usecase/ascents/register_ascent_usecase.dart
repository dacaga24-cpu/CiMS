import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/ascent.dart';
import 'package:cims/core/entity/ascent_upload_photo.dart';

// Aquest cas d’ús registra una nova ascensió.
// Centralitza aquesta operació perquè la pantalla no hagi de comunicar-se directament amb l’API.
class RegisterAscentUseCase {
  const RegisterAscentUseCase(this._apiClient);

  // Aquest client permet crear l’ascensió a través del backend.
  // Això manté la pantalla separada dels detalls de la petició.
  final ApiClient _apiClient;

  // Envia les dades necessàries per registrar una ascensió.
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
