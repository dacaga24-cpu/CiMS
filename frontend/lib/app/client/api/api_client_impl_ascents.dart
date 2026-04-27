part of 'api_client_impl.dart';

// Aquest mixin implementa les peticions relacionades amb les ascensions.
// Permet registrar i consultar ascensions per a l’usuari autenticat mantenint
// la comunicació amb el backend separada de la pantalla i del controller.
mixin _AscentsApiClientImplMixin on _ApiClientBase implements AscentsApiClient {
  // Aquest mètode envia al backend les dades d’una nova ascensió.
  // La data s’envia en format YYYY-MM-DD, que és el format esperat per l’API.
  @override
  Future<Ascent> createAscent({
    required int peakId,
    required DateTime ascentDate,
    String? notes,
  }) async {
    try {
      final response = await _postJson(
        ApiEndpoints.ascents,
        body: {
          'peakId': peakId,
          'ascentDate': _formatDateOnly(ascentDate),
          if (notes != null) 'notes': notes,
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
}
