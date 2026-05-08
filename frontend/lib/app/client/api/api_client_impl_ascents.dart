part of 'api_client_impl.dart';

// Aquest mixin implementa les peticions relacionades amb les ascensions.
// Permet registrar i consultar ascensions per a l’usuari autenticat mantenint
// la comunicació amb el backend separada de la pantalla i del controller.
mixin _AscentsApiClientImplMixin on _ApiClientBase implements AscentsApiClient {
  // Aquest mètode envia al backend les dades d’una nova ascensió.
  // La data s’envia en format YYYY-MM-DD, que és el format esperat per l’API.
  // Si l’usuari ha seleccionat fotos, també s’envien les rutes ja pujades a GCS.
  @override
  Future<Ascent> createAscent({
    required int peakId,
    required DateTime ascentDate,
    String? notes,
    List<AscentUploadPhoto> photos = const [],
  }) async {
    try {
      final response = await _postJson(
        ApiEndpoints.ascents,
        body: {
          'peakId': peakId,
          'ascentDate': _formatDateOnly(ascentDate),
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
            'La resposta del registre d’ascensió no és vàlida',
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

  // Aquest mètode actualitza una ascensió existent al backend.
  // Manté el registre original i només modifica les dades editables del formulari.
  @override
  Future<Ascent> updateAscent({
    required int ascentId,
    required DateTime ascentDate,
    String? notes,
  }) async {
    try {
      final response = await _putJson(
        ApiEndpoints.ascentById(ascentId),
        body: {
          'ascentDate': _formatDateForApi(ascentDate),
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

  // Aquest mètode recupera totes les fotos d’una ascensió existent.
  // Es fa servir a la pantalla d’edició per mostrar les imatges ja associades.
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

  // Aquest mètode demana al backend una URL temporal per pujar una foto.
  // La imatge encara no queda associada a cap ascensió fins que s’envia el formulari final.
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

  // Aquest mètode puja els bytes de la imatge directament a la URL temporal de GCS.
  // Aquesta petició no fa servir el backend ni el token, perquè la URL ja
  // incorpora el permís temporal. Els headers han de coincidir exactament
  // amb els que el backend va incloure en signar la URL: Content-Type sempre
  // i, si la signatura porta extensionHeaders (x-goog-content-length-range),
  // també aquests. Si en falta cap, GCS retorna 403 SignatureDoesNotMatch.
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

  // Aquest mètode recupera les ascensions de l’usuari autenticat
  // associades a un cim concret. Es farà servir per mostrar informació
  // personal del cim, com la data de l’última ascensió registrada.
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

  // Aquest mètode transforma una data en el format simple que fa servir
  // el backend per guardar ascensions sense hora.
  String _formatDateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // Aquest mètode transforma una data de Dart al format que espera el backend.
  String _formatDateForApi(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$year-$month-$day';
}
}
