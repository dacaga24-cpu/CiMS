part of 'api_client_impl.dart';

// Aquest mixin agrupa les operacions relacionades amb el catàleg
// i el detall dels cims dins del client d’API.
mixin _PeaksApiClientImplMixin on _ApiClientBase {
  // Aquest mètode recupera el catàleg de cims i permet aplicar criteris
  // de cerca o filtratge per retornar només els resultats que interessen a l’usuari.
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

      // Si la resposta és correcta, es valida que el cos sigui una llista
      // i es transforma cada element en un objecte Peak del sistema.
      if (response.statusCode == 200) {
        final data = _tryParseJsonList(response.body);

        if (data == null) {
          throw const ApiException(
            'La resposta del catàleg no és vàlida',
            statusCode: 200,
          );
        }

        return data
            .whereType<Map<String, dynamic>>()
            .map(Peak.fromJson)
            .toList();
      }

      final Map<String, dynamic>? data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut carregar el catàleg de cims';

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

  // Aquest mètode recupera el detall d’un cim concret a partir del seu identificador.
  // És útil per carregar la pantalla de detall i admet tant una resposta directa
  // com una resposta on el cim arribi dins del camp "peak".
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
}
