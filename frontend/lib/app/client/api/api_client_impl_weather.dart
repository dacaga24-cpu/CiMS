part of 'api_client_impl.dart';

// Aquest mixin implementa la comunicació amb els endpoints meteorològics.
// Permet que la pantalla de detall del cim consulti la previsió sense dependre directament de l’HTTP.
mixin _WeatherApiClientImplMixin on _ApiClientBase implements WeatherApiClient {
  // Aquest mètode recupera la previsió diària d’un cim.
  // El nombre de dies només s’envia si s’ha indicat, mantenint el valor per defecte al backend.
  @override
  Future<PeakWeather> getPeakDailyWeather(
    int peakId, {
    int? days,
  }) async {
    try {
      final response = await _getJson(
        ApiEndpoints.peakWeatherDaily(peakId),
        queryParameters: {
          if (days != null) 'days': days.toString(),
        },
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = _tryParseJson(response.body);

        if (data == null) {
          throw const ApiException(
            'La resposta de la previsió meteorològica no és vàlida',
            statusCode: 200,
          );
        }

        return PeakWeather.fromJson(data);
      }

      final data = _tryParseJson(response.body);

      // Aquest bloc conserva el missatge i el codi d’error retornats pel backend.
      // Això permet que la interfície distingeixi incidències del proveïdor meteorològic.
      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut carregar la previsió meteorològica';

      throw ApiException(
        message,
        statusCode: response.statusCode,
        code: data?['code']?.toString(),
      );
    } on TimeoutException {
      throw const ApiException(
        'El servidor no respon. Torna-ho a provar',
      );
    } catch (error) {
      if (error is ApiException) rethrow;

      // Els errors interns de programació es mantenen perquè es puguin diagnosticar correctament.
      if (error is Error) rethrow;

      throw const ApiException(
        'No s\'ha pogut connectar amb el servidor',
      );
    }
  }

  // Aquest mètode recupera la previsió horària d’un cim per a una data concreta.
  // La data s’envia com a filtre perquè el backend retorni només les hores corresponents.
  @override
  Future<PeakHourlyWeather> getPeakHourlyWeather(
    int peakId,
    String date,
  ) async {
    try {
      final response = await _getJson(
        ApiEndpoints.peakWeatherHourly(peakId),
        queryParameters: {'date': date},
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = _tryParseJson(response.body);

        if (data == null) {
          throw const ApiException(
            'La resposta de la previsió horària no és vàlida',
            statusCode: 200,
          );
        }

        return PeakHourlyWeather.fromJson(data);
      }

      final data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut carregar la previsió horària';

      throw ApiException(
        message,
        statusCode: response.statusCode,
        code: data?['code']?.toString(),
      );
    } on TimeoutException {
      throw const ApiException(
        'El servidor no respon. Torna-ho a provar',
      );
    } catch (error) {
      if (error is ApiException) rethrow;
      if (error is Error) rethrow;

      throw const ApiException(
        'No s\'ha pogut connectar amb el servidor',
      );
    }
  }
}
