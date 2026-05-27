import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/ascent_photo.dart';
import 'package:cims/core/entity/ascent_upload_photo.dart';

// Aquest cas d’ús associa fotos noves a una ascensió existent.
// Les imatges ja han estat pujades al bucket i aquí només es desa la relació amb l’ascensió.
class AddAscentPhotosUseCase {
  const AddAscentPhotosUseCase(this._apiClient);

  // Aquest client permet comunicar el cas d’ús amb el backend.
  // Manté separada la lògica de la pantalla de la petició real a l’API.
  final ApiClient _apiClient;

  // Executa l’associació de fotos amb una ascensió concreta.
  // Retorna les fotos creades perquè la interfície pugui actualitzar-se amb les dades definitives.
  Future<List<AscentPhoto>> call({
    required int ascentId,
    required List<AscentUploadPhoto> photos,
  }) {
    return _apiClient.addAscentPhotos(
      ascentId: ascentId,
      photos: photos,
    );
  }
}
