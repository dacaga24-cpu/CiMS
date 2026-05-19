import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/ascent_photo_gallery.dart';
import 'package:cims/core/usecase/ascents/delete_ascent_photo_usecase.dart';
import 'package:cims/core/usecase/get_user_photo_gallery_usecase.dart';
import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:flutter/material.dart';

// Aquest controller gestiona l'estat de la galeria de fotos de l'usuari.
// Controla la càrrega inicial, la paginació, els errors, l'eliminació
// de fotos i la llista acumulada d'imatges.
class UserPhotoGalleryController extends ChangeNotifier {
  UserPhotoGalleryController({
    GetUserPhotoGalleryUseCase? getUserPhotoGalleryUseCase,
    DeleteAscentPhotoUseCase? deleteAscentPhotoUseCase,
  })  : _getUserPhotoGalleryUseCase =
            getUserPhotoGalleryUseCase ?? GetUserPhotoGalleryUseCase(),
        _deleteAscentPhotoUseCase = deleteAscentPhotoUseCase ??
            DeleteAscentPhotoUseCase(ApiClientImpl());

  final GetUserPhotoGalleryUseCase _getUserPhotoGalleryUseCase;

  // Aquest cas d’ús permet eliminar una foto concreta de la galeria.
  // El backend valida que la imatge pertanyi a l’usuari autenticat.
  final DeleteAscentPhotoUseCase _deleteAscentPhotoUseCase;

  static const int _pageLimit = 30;

  final List<AscentPhotoGalleryItem> _photos = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _nextOffset = 0;
  String? _errorMessage;
  int? _deletingPhotoId;

  List<AscentPhotoGalleryItem> get photos => List.unmodifiable(_photos);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  // Aquest valor indica quina foto s’està eliminant.
  // Permet mostrar un indicador només sobre aquella imatge.
  int? get deletingPhotoId => _deletingPhotoId;

  // Carrega la primera pàgina de la galeria.
  // Es fa servir quan la pantalla s'obre per primera vegada o quan es força una recàrrega.
  Future<void> loadInitial() async {
    if (_isLoading) return;

    _isLoading = true;
    _isLoadingMore = false;
    _errorMessage = null;
    _hasMore = true;
    _nextOffset = 0;
    _photos.clear();
    notifyListeners();

    try {
      final page = await _getUserPhotoGalleryUseCase.execute(
        limit: _pageLimit,
        offset: 0,
      );

      _photos.addAll(page.items);
      _hasMore = page.hasMore;
      _nextOffset = page.nextOffset ?? _photos.length;
    } catch (error) {
      _errorMessage = _resolveErrorMessage(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Torna a carregar la galeria des del principi.
  // S'utilitza amb el gest de refrescar o amb el botó de reintent.
  Future<void> refresh() {
    return loadInitial();
  }

  // Carrega la següent pàgina de fotos quan l'usuari arriba al final.
  // Evita peticions duplicades i no fa cap crida si ja no queden més resultats.
  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _getUserPhotoGalleryUseCase.execute(
        limit: _pageLimit,
        offset: _nextOffset,
      );

      _photos.addAll(page.items);
      _hasMore = page.hasMore;
      _nextOffset = page.nextOffset ?? _photos.length;
    } catch (error) {
      _errorMessage = _resolveErrorMessage(error);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Aquest mètode elimina una foto concreta de la galeria.
  // Si l’operació funciona, la imatge desapareix de la llista local sense recarregar tota la pantalla.
  Future<void> deletePhoto(int photoId) async {
    if (_isLoading || _isLoadingMore || _deletingPhotoId != null) {
      return;
    }

    _deletingPhotoId = photoId;
    _errorMessage = null;
    notifyListeners();

    try {
      await _deleteAscentPhotoUseCase(photoId);
      _photos.removeWhere((photo) => photo.id == photoId);
    } catch (error) {
      _errorMessage = _resolveDeleteErrorMessage(error);
    } finally {
      _deletingPhotoId = null;
      notifyListeners();
    }
  }

  // Repeteix la càrrega segons l'estat actual de la pantalla.
  // Si encara no hi ha fotos, recupera la primera pàgina; si ja n'hi ha, intenta continuar.
  Future<void> retry() {
    if (_photos.isEmpty) {
      return loadInitial();
    }

    return loadMore();
  }

  // Converteix errors tècnics en missatges comprensibles per a la interfície.
  // Manté el tractament d'errors concentrat dins del controller.
  String _resolveErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'No s\'ha pogut carregar la galeria de fotos';
  }

  // Converteix errors d’eliminació en missatges comprensibles per a la pantalla.
  String _resolveDeleteErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'No s\'ha pogut eliminar la foto';
  }
}
