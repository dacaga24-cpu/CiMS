part of 'api_client_impl.dart';

// Aquest mixin agrupa les operacions relacionades amb les comarques disponibles.
// Permet obtenir les regions que s’utilitzen als filtres i altres pantalles de l’aplicació.
mixin _RegionsApiClientImplMixin on _ApiClientBase {
  // Aquest mètode recupera la llista de comarques des del backend.
  // Transforma la resposta en objectes Region perquè la resta de l’aplicació les pugui utilitzar.
  Future<List<Region>> getRegions() async {
    try {
      final response = await _getJson(ApiEndpoints.regions);

      if (response.statusCode == 200) {
        final data = _tryParseJsonList(response.body);

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

      final Map<String, dynamic>? data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'han pogut carregar les comarques';

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
