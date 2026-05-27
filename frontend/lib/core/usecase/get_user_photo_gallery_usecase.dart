import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/ascent_photo_gallery.dart';

// Aquest cas d’ús recupera una pàgina de la galeria de fotos de l’usuari.
// Manté la pantalla separada del client API i permet reutilitzar aquesta acció en altres punts de l’aplicació.
class GetUserPhotoGalleryUseCase {
  GetUserPhotoGalleryUseCase({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClientImpl();

  // Aquest client permet obtenir la galeria a través del backend.
  // Això manté el cas d’ús separat de la implementació concreta de l’API.
  final ApiClient _apiClient;

  // Recupera una pàgina concreta de fotos de l’usuari.
  // El limit indica quantes imatges es carreguen i offset des de quina posició continuar.
  Future<AscentPhotoGalleryPage> execute({
    int limit = 30,
    int offset = 0,
  }) {
    return _apiClient.getUserPhotoGallery(
      limit: limit,
      offset: offset,
    );
  }
}