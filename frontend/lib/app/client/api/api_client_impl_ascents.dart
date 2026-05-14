part of 'api_client_impl.dart';

// Aquest mixin agrupa les peticions d’ascensions del client API.
// Manté separada la comunicació amb el backend de les pantalles i controllers.
mixin _AscentsApiClientImplMixin on _ApiClientBase implements AscentsApiClient {
  // Envia al backend una nova ascensió manual.
  // Pot incloure data, notes i fotos que ja s’han pujat prèviament a GCS.
  @override
  Future<Ascent> createAscent({
    required int peakId,
    DateTime? ascentDate,
    String? notes,
    List<AscentUploadPhoto> photos = const [],
  }) async {
    try {
      final response = await _postJson(
        ApiEndpoints.ascents,
        body: {
          'peakId': peakId,
          if (ascentDate != null) 'ascentDate': _formatDateOnly(ascentDate),
          if (notes != null) 'notes': notes,
          if (photos.isNotEmpty)
            'photos': photos.map((photo) => photo.toJson()).toList(),
        },
        requiresAuth: true,
      );

      if (response.statusCode == 201) {
        final data = _tryParseJson(response.body);

        if (data == null) {
          throw const ApiException(
            'La resposta del registre d\'ascensió no és vàlida',
            statusCode: 201,
          );
        }

        return Ascent.fromJson(data);
      }

      final data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut registrar l\'ascensió';

      throw ApiException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const ApiException(
        'El servidor no respon. Torna-ho a provar',
      );
    } catch (error) {
      if (error is ApiException) rethrow;

      throw const ApiException(
        'No s\'ha pogut connectar amb el servidor',
      );
    }
  }

  // Envia al backend una ascensió verificada.
  // Utilitza una foto feta des de l’app i la ubicació capturada pel dispositiu.
  @override
  Future<Ascent> createVerifiedAscent({
    required int peakId,
    String? notes,
    required List<AscentUploadPhoto> photos,
    required double capturedLatitude,
    required double capturedLongitude,
    required double capturedAccuracyMeters,
    required DateTime capturedAt,
  }) async {
    try {
      final response = await _postJson(
        ApiEndpoints.verifiedAscent,
        body: {
          'peakId': peakId,
          if (notes != null) 'notes': notes,
          'photos': photos.map((photo) => photo.toJson()).toList(),
          'capturedLatitude': capturedLatitude,
          'capturedLongitude': capturedLongitude,
          'capturedAccuracyMeters': capturedAccuracyMeters,
          'capturedAt': capturedAt.toIso8601String(),
        },
        requiresAuth: true,
      );

      if (response.statusCode == 201) {
        final data = _tryParseJson(response.body);

        if (data == null) {
          throw const ApiException(
            'La resposta de l\'ascensió verificada no és vàlida',
            statusCode: 201,
          );
        }

        return Ascent.fromJson(data);
      }

      final data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut crear l\'ascensió verificada';

      throw ApiException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const ApiException(
        'El servidor no respon. Torna-ho a provar',
      );
    } catch (error) {
      if (error is ApiException) rethrow;

      throw const ApiException(
        'No s\'ha pogut connectar amb el servidor',
      );
    }
  }

  // Actualitza una ascensió existent.
  // Pot ometre la data quan el registre prové d’una verificació i la data està bloquejada.
  @override
  Future<Ascent> updateAscent({
    required int ascentId,
    required DateTime? ascentDate,
    bool includeAscentDate = true,
    String? notes,
  }) async {
    try {
      final response = await _putJson(
        ApiEndpoints.ascentById(ascentId),
        body: {
          if (includeAscentDate)
            'ascentDate':
                ascentDate == null ? null : _formatDateOnly(ascentDate),
          'notes': notes,
        },
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = _tryParseJson(response.body);

        if (data == null) {
          throw const ApiException(
            'La resposta de l\'actualització no és vàlida',
            statusCode: 200,
          );
        }

        final rawAscent = data['ascent'] ?? data['data'] ?? data;

        if (rawAscent is! Map) {
          throw const ApiException(
            'La resposta de l\'actualització no conté cap ascensió vàlida',
            statusCode: 200,
          );
        }

        return Ascent.fromJson(
          Map<String, dynamic>.from(rawAscent),
        );
      }

      final data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut actualitzar l\'ascensió';

      throw ApiException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const ApiException(
        'El servidor no respon. Torna-ho a provar',
      );
    } catch (error) {
      if (error is ApiException) rethrow;

      throw const ApiException(
        'No s\'ha pogut connectar amb el servidor',
      );
    }
  }

  // Recupera totes les fotos d’una ascensió.
  // S’utilitza a l’edició i al detall per mostrar les imatges ja associades.
  @override
  Future<List<AscentPhoto>> getAscentPhotos(int ascentId) async {
    try {
      final response = await _getJson(
        ApiEndpoints.ascentPhotosByAscentId(ascentId),
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);

        if (decodedBody is! List) {
          throw const ApiException(
            'La resposta de les fotos no és vàlida',
            statusCode: 200,
          );
        }

        return decodedBody
            .whereType<Map>()
            .map((item) => AscentPhoto.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }

      final data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'han pogut carregar les fotos de l\'ascensió';

      throw ApiException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const ApiException(
        'El servidor no respon. Torna-ho a provar',
      );
    } catch (error) {
      if (error is ApiException) rethrow;

      throw const ApiException(
        'No s\'ha pogut connectar amb el servidor',
      );
    }
  }

  // Demana al backend una URL temporal per pujar una foto.
  // La foto encara no queda associada a cap ascensió fins que es desa el registre final.
  @override
  Future<AscentSignedUploadUrl> createAscentPhotoSignedUploadUrl({
    required String mimeType,
    bool isPrimary = false,
  }) async {
    try {
      final response = await _postJson(
        ApiEndpoints.ascentPhotoSignedUploadUrl,
        body: {
          'mimeType': mimeType,
          'isPrimary': isPrimary,
        },
        requiresAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _tryParseJson(response.body);

        if (data == null) {
          throw ApiException(
            'La resposta de pujada d\'imatge no és vàlida',
            statusCode: response.statusCode,
          );
        }

        return AscentSignedUploadUrl.fromJson(data);
      }

      final data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut preparar la pujada de la imatge';

      throw ApiException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const ApiException(
        'El servidor no respon. Torna-ho a provar',
      );
    } catch (error) {
      if (error is ApiException) rethrow;

      throw const ApiException(
        'No s\'ha pogut preparar la pujada de la imatge',
      );
    }
  }

  // Puja els bytes de la imatge directament a Google Cloud Storage.
  // Utilitza la URL temporal i els headers signats que ha retornat el backend.
  @override
  Future<void> uploadAscentPhotoBytes({
    required String uploadUrl,
    required List<int> bytes,
    required Map<String, String> headers,
  }) async {
    try {
      final response = await _client
          .put(
            Uri.parse(uploadUrl),
            headers: headers,
            body: bytes,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        return;
      }

      throw ApiException(
        'No s\'ha pogut pujar la imatge',
        statusCode: response.statusCode,
      );
    } on TimeoutException {
      throw const ApiException(
        'La pujada de la imatge ha trigat massa',
      );
    } catch (error) {
      if (error is ApiException) rethrow;

      throw const ApiException(
        'No s\'ha pogut pujar la imatge',
      );
    }
  }

  // Recupera les ascensions de l’usuari associades a un cim concret.
  // Permet mostrar l’historial personal dins del detall del cim.
  @override
  Future<List<Ascent>> getAscentsByPeak(int peakId) async {
    try {
      final response = await _getJson(
        ApiEndpoints.ascentsByPeakId(peakId),
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);

        if (decodedBody is! List) {
          throw const ApiException(
            'La resposta de les ascensions no és vàlida',
            statusCode: 200,
          );
        }

        return decodedBody
            .whereType<Map<String, dynamic>>()
            .map(Ascent.fromJson)
            .toList();
      }

      final data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'han pogut carregar les ascensions del cim';

      throw ApiException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const ApiException(
        'El servidor no respon. Torna-ho a provar',
      );
    } catch (error) {
      if (error is ApiException) rethrow;

      throw const ApiException(
        'No s\'ha pogut connectar amb el servidor',
      );
    }
  }

  // Recupera una pàgina de la galeria de fotos de l’usuari.
  // La paginació permet carregar més imatges només quan la pantalla les necessita.
  @override
  Future<AscentPhotoGalleryPage> getUserPhotoGallery({
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final response = await _getJson(
        ApiEndpoints.ascentPhotosGallery,
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = _tryParseJson(response.body);

        if (data == null) {
          throw const ApiException(
            'La resposta de la galeria de fotos no és vàlida',
            statusCode: 200,
          );
        }

        return AscentPhotoGalleryPage.fromJson(data);
      }

      final data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut carregar la galeria de fotos';

      throw ApiException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const ApiException(
        'El servidor no respon. Torna-ho a provar',
      );
    } catch (error) {
      if (error is ApiException) rethrow;

      throw const ApiException(
        'No s\'ha pogut connectar amb el servidor',
      );
    }
  }

  // Converteix una data al format simple que espera el backend.
  // Aquest format s’utilitza per guardar ascensions sense hora.
  String _formatDateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // Elimina una foto d’ascensió de l’usuari autenticat.
  // Si era la foto principal, el backend pot promocionar-ne una altra.
  @override
  Future<void> deleteAscentPhoto(int photoId) async {
    final response = await _deleteJson(
      ApiEndpoints.ascentPhotoById(photoId),
      requiresAuth: true,
    );

    if (response.statusCode == 204) {
      return;
    }

    throw ApiException(
      'No s\'ha pogut eliminar la foto',
      statusCode: response.statusCode,
    );
  }

  // Elimina una ascensió de l’usuari autenticat.
  // També permet al backend actualitzar l’estat del cim i el progrés mensual.
  @override
  Future<void> deleteAscent(int ascentId) async {
    final response = await _deleteJson(
      ApiEndpoints.ascentById(ascentId),
      requiresAuth: true,
    );

    if (response.statusCode == 204) {
      return;
    }

    throw ApiException(
      'No s\'ha pogut eliminar l\'ascensió',
      statusCode: response.statusCode,
    );
  }
}