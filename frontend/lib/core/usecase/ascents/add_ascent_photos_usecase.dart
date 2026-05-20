import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/ascent_photo.dart';
import 'package:cims/core/entity/ascent_upload_photo.dart';

// Aquest cas d’ús associa fotos noves a una ascensió existent.
// Les imatges ja han estat pujades al bucket i aquí només es desa la relació amb l’ascensió.
class AddAscentPhotosUseCase {
  const AddAscentPhotosUseCase(this._apiClient);

  final ApiClient _apiClient;

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