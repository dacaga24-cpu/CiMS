import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/ascent.dart';
import 'package:cims/core/entity/ascent_upload_photo.dart';

// Aquest cas d’ús crea una ascensió verificada a partir d’una foto
// i de la ubicació capturada pel dispositiu.
// Centralitza l’acció perquè la pantalla no depengui directament del client API.
class CreateVerifiedAscentUseCase {
  const CreateVerifiedAscentUseCase(this._apiClient);

  // Aquest client permet comunicar el cas d’ús amb el backend.
  // Manté separada la lògica de la pantalla de la petició real a l’API.
  final ApiClient _apiClient;

  // Aquest mètode envia al backend les dades necessàries per crear una ascensió verificada.
  // Inclou el cim seleccionat, la foto d’evidència, la ubicació capturada i el moment de captura.
  Future<Ascent> call({
    required int peakId,
    String? notes,
    required List<AscentUploadPhoto> photos,
    required double capturedLatitude,
    required double capturedLongitude,
    required double capturedAccuracyMeters,
    required DateTime capturedAt,
  }) {
    return _apiClient.createVerifiedAscent(
      peakId: peakId,
      notes: notes,
      photos: photos,
      capturedLatitude: capturedLatitude,
      capturedLongitude: capturedLongitude,
      capturedAccuracyMeters: capturedAccuracyMeters,
      capturedAt: capturedAt,
    );
  }
}
