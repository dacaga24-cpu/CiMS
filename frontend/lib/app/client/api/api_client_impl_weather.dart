part of 'api_client_impl.dart';

// Aquest mixin implementa la comunicació amb els endpoints meteorològics.
// La pantalla de detall del cim consumeix aquest contracte sense conèixer
// la implementació HTTP concreta, igual que fa amb la resta de mòduls.
mixin _WeatherApiClientImplMixin on _ApiClientBase implements WeatherApiClient {
  // Aquest mètode recupera la previsió diària d'un cim. days es passa al
  // backend com a query string només si el cridant l'ha indicat: així el
  // valor per defecte (7 dies) viu en un únic lloc, al servidor, i no es
  // duplica entre frontend i backend.
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

      // El backend retorna 503 quan Google no està disponible. La capa
      // de presentació mostrarà un missatge específic per a aquest cas
      // perquè l'usuari entengui que el problema no és del servidor de
      // CiMS, sinó del proveïdor meteorològic. El codi simbòlic
      // (WEATHER_PROVIDER_UNAVAILABLE) viatja amb l'excepció perquè els
      // controllers puguin reaccionar al cas sense haver de fer match
      // contra el missatge traduït.
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

      // Els errors de programació (Error i subclasses com TypeError o
      // RangeError) es tornen a llançar sense col·lapsar-los al missatge
      // genèric: el controller els atrapa al catch (error, stackTrace) i
      // els loguega amb runtimeType i stack. Sense aquest rethrow, un
      // bug de mapping en PeakWeather.fromJson arribaria a la UI com a
      // "no es pot connectar" i no quedaria cap rastre al log per
      // investigar-lo.
      if (error is Error) rethrow;

      throw const ApiException(
        'No s\'ha pogut connectar amb el servidor',
      );
    }
  }

  // Aquest mètode recupera la previsió horària d'un cim per a una data
  // concreta. La data viatja com a query string perquè és un paràmetre
  // de selecció (com els filtres del catàleg), no un identificador del
  // recurs base; el recurs continua sent el cim, definit pel peakId que
  // ja és segment de ruta.
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
