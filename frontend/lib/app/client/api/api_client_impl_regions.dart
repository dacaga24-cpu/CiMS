part of 'api_client_impl.dart';

// Aquest mixin agrupa les operacions relacionades amb la càrrega
// de comarques o regions disponibles a l’aplicació.
mixin _RegionsApiClientImplMixin on _ApiClientBase {
  // Aquest mètode recupera la llista de comarques des del backend.
  // Si la resposta és correcta, transforma les dades rebudes en objectes Region
  // perquè la resta de l’aplicació les pugui utilitzar.
  Future<List<Region>> getRegions() async {
    try {
      final response = await _getJson(ApiEndpoints.regions);

      // Si el servidor respon correctament, es valida que el cos sigui una llista
      // i es converteix cada element en una comarca del sistema.
      if (response.statusCode == 200) {
        final data = _tryParseJsonList(response.body);

        // Aquest control evita continuar amb dades mal formades encara que el servidor
        // hagi respost amb èxit.
        if (data == null) {
          throw const ApiException(
            'La resposta de les comarques no és vàlida',
            statusCode: 200,
          );
        }

        return data
            .whereType<Map<String, dynamic>>()
            .map(Region.fromJson)
            .toList();
      }

      // Si la petició no ha anat bé, s’intenta recuperar un missatge d’error útil
      // per mostrar una resposta més clara a l’usuari.
      final Map<String, dynamic>? data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'han pogut carregar les comarques';

      throw ApiException(message, statusCode: response.statusCode);
    } on TimeoutException {
      // Aquest cas controla quan el servidor tarda massa a respondre.
      throw const ApiException(
        'El servidor no respon. Torna-ho a provar',
      );
    } catch (error) {
      // Si l’error ja estava controlat com a ApiException, es conserva tal com està.
      // En qualsevol altre cas, es retorna un missatge genèric de connexió.
      if (error is ApiException) rethrow;

      throw const ApiException(
        'No s\'ha pogut connectar amb el servidor',
      );
    }
  }
}
