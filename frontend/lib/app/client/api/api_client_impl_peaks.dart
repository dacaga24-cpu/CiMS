part of 'api_client_impl.dart';

// Aquest mixin agrupa les operacions relacionades amb el catàleg i el detall dels cims.
// Manté separada la comunicació amb el backend de les pantalles que consumeixen aquestes dades.
mixin _PeaksApiClientImplMixin on _ApiClientBase {
  // Aquest helper transforma errors inesperats en una resposta controlada per l’aplicació.
  // També deixa un registre útil per diagnosticar problemes de comunicació o format.
  Never _throwUnexpectedPeaksError(Object error, StackTrace stack) {
    if (error is ApiException) throw error;

    debugPrint(
      '[ApiClientImpl peaks] unexpected (${error.runtimeType}): $error\n$stack',
    );

    throw const ApiException(
      'No s\'ha pogut connectar amb el servidor',
    );
  }

  // Aquest mètode construeix els paràmetres de consulta del catàleg.
  // Permet reutilitzar els mateixos filtres al llistat paginat i al mapa.
  Map<String, String> _peaksQueryParameters({
    String? search,
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
    String? status,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? pageSize,
  }) {
    return <String, String>{
      if (page != null) 'page': page.toString(),
      if (pageSize != null) 'pageSize': pageSize.toString(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (regionId != null) 'regionId': regionId.toString(),
      if (minAltitude != null) 'minAltitude': minAltitude.toString(),
      if (maxAltitude != null) 'maxAltitude': maxAltitude.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
      if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
      if (sortOrder != null && sortOrder.isNotEmpty) 'sortOrder': sortOrder,
    };
  }

  // Aquest mètode recupera el catàleg de cims.
  // Permet aplicar filtres bàsics per retornar només els resultats que interessen a l’usuari.
  Future<List<Peak>> getPeaks({
    String? search,
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
  }) async {
    try {
      final response = await _getJson(
        ApiEndpoints.peaks,
        queryParameters: {
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (regionId != null) 'regionId': regionId.toString(),
          if (minAltitude != null) 'minAltitude': minAltitude.toString(),
          if (maxAltitude != null) 'maxAltitude': maxAltitude.toString(),
        },
      );

      // Aquesta validació accepta els formats previstos de resposta del catàleg.
      // Això permet transformar les dades rebudes en entitats de l’aplicació.
      if (response.statusCode == 200) {
        final directList = _tryParseJsonList(response.body);

        final List<dynamic>? data;
        if (directList != null) {
          data = directList;
        } else {
          final wrappedData = _tryParseJson(response.body);
          final rawPeaks = wrappedData?['items'] ??
              wrappedData?['peaks'] ??
              wrappedData?['data'] ??
              wrappedData?['results'];

          data = rawPeaks is List ? rawPeaks : null;
        }

        if (data == null) {
          throw const ApiException(
            'La resposta del catàleg no és vàlida',
            statusCode: 200,
          );
        }

        return data
            .whereType<Map>()
            .map((item) => Peak.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }

      final Map<String, dynamic>? data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut carregar el catàleg de cims';

      throw ApiException(
        message,
        statusCode: response.statusCode,
        code: data?['code']?.toString(),
      );
    } on TimeoutException {
      throw const ApiException(
        'El servidor no respon. Torna-ho a provar',
      );
    } catch (error, stack) {
      _throwUnexpectedPeaksError(error, stack);
    }
  }

  // Aquest mètode recupera una pàgina concreta del catàleg de cims.
  // Manté la paginació i els filtres perquè la pantalla pugui carregar més resultats progressivament.
  Future<PeaksPage> getPeaksPage({
    String? search,
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
    String? status,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _getJson(
        ApiEndpoints.peaks,
        queryParameters: _peaksQueryParameters(
          search: search,
          regionId: regionId,
          minAltitude: minAltitude,
          maxAltitude: maxAltitude,
          status: status,
          sortBy: sortBy,
          sortOrder: sortOrder,
          page: page,
          pageSize: pageSize,
        ),
        attachTokenIfAvailable: true,
      );

      if (response.statusCode == 200) {
        final data = _tryParseJson(response.body);

        if (data == null) {
          throw const ApiException(
            'La resposta paginada del catàleg no és vàlida',
            statusCode: 200,
          );
        }

        return PeaksPage.fromJson(data);
      }

      final Map<String, dynamic>? data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut carregar la pàgina del catàleg';

      throw ApiException(
        message,
        statusCode: response.statusCode,
        code: data?['code']?.toString(),
      );
    } on TimeoutException {
      throw const ApiException(
        'El servidor no respon. Torna-ho a provar',
      );
    } catch (error, stack) {
      _throwUnexpectedPeaksError(error, stack);
    }
  }

  // Aquest mètode recupera els cims destinats al mapa.
  // Envia els filtres principals perquè la vista pugui mostrar marcadors coherents amb el catàleg.
  Future<List<Peak>> getMapPeaks({
    String? search,
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
    String? status,
  }) async {
    try {
      final response = await _getJson(
        ApiEndpoints.peaksMap,
        queryParameters: _peaksQueryParameters(
          search: search,
          regionId: regionId,
          minAltitude: minAltitude,
          maxAltitude: maxAltitude,
          status: status,
        ),
        attachTokenIfAvailable: true,
      );

      if (response.statusCode == 200) {
        final directList = _tryParseJsonList(response.body);

        final List<dynamic>? data;
        if (directList != null) {
          data = directList;
        } else {
          final wrappedData = _tryParseJson(response.body);
          final rawPeaks = wrappedData?['items'] ??
              wrappedData?['peaks'] ??
              wrappedData?['data'] ??
              wrappedData?['results'];

          data = rawPeaks is List ? rawPeaks : null;
        }

        if (data == null) {
          throw const ApiException(
            'La resposta del mapa no és vàlida',
            statusCode: 200,
          );
        }

        return data
            .whereType<Map>()
            .map((item) => Peak.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }

      final Map<String, dynamic>? data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'han pogut carregar els cims del mapa';

      throw ApiException(
        message,
        statusCode: response.statusCode,
        code: data?['code']?.toString(),
      );
    } on TimeoutException {
      throw const ApiException(
        'El servidor no respon. Torna-ho a provar',
      );
    } catch (error, stack) {
      _throwUnexpectedPeaksError(error, stack);
    }
  }

  // Aquest mètode recupera el detall d’un cim concret.
  // Accepta els formats de resposta previstos i retorna una entitat preparada per a la pantalla de detall.
  Future<Peak> getPeakById(int peakId) async {
    try {
      final response = await _getJson(
        ApiEndpoints.peakById(peakId),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic>? data = _tryParseJson(response.body);

        if (data == null) {
          throw const ApiException(
            'La resposta del detall del cim no és vàlida',
            statusCode: 200,
          );
        }

        final dynamic peakRaw = data['peak'];
        final Map<String, dynamic> peakJson =
            peakRaw is Map<String, dynamic> ? peakRaw : data;

        return Peak.fromJson(peakJson);
      }

      final Map<String, dynamic>? data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut carregar el detall del cim';

      throw ApiException(
        message,
        statusCode: response.statusCode,
        code: data?['code']?.toString(),
      );
    } on TimeoutException {
      throw const ApiException(
        'El servidor no respon. Torna-ho a provar',
      );
    } catch (error, stack) {
      _throwUnexpectedPeaksError(error, stack);
    }
  }
}
