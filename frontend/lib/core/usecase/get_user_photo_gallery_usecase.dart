import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/ascent_photo_gallery.dart';

// Aquest cas d'ús recupera una pàgina de la galeria de fotos de l'usuari.
// Manté la pantalla separada del client API i permet reutilitzar aquesta acció
// si més endavant la galeria també es mostra des d'altres punts de l'aplicació.
class GetUserPhotoGalleryUseCase {
  GetUserPhotoGalleryUseCase({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClientImpl();

  final ApiClient _apiClient;

  // Aquest mètode demana una pàgina concreta de fotos.
  // El limit defineix quantes imatges es volen carregar i offset indica
  // des de quina posició s'ha de continuar.
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