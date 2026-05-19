import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/ascent.dart';
import 'package:cims/core/entity/ascent_upload_photo.dart';

// Aquest cas d’ús crea una ascensió verificada a partir d’una foto
// i de la ubicació capturada pel dispositiu.
// Centralitza l’acció perquè la pantalla no depengui directament del client API.
class CreateVerifiedAscentUseCase {
  const CreateVerifiedAscentUseCase(this._apiClient);

  final ApiClient _apiClient;

  // Aquest mètode envia al backend les dades necessàries per crear
  // una ascensió verificada: cim seleccionat, foto, coordenades,
  // precisió i moment real de captura.
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
