part of 'api_client_impl.dart';

// Aquest mixin implementa la comunicació amb l’endpoint d’estadístiques.
// Manté la petició separada de la pantalla perquè la UI només treballi
// amb l’entitat UserStats i no amb respostes HTTP directes.
mixin _StatsApiClientImplMixin on _ApiClientBase implements StatsApiClient {
  // Aquest mètode recupera les estadístiques de l’usuari autenticat.
  // És una petició protegida perquè les dades depenen del token de sessió.
  @override
  Future<UserStats> getUserStats() async {
    try {
      final response = await _getJson(
        ApiEndpoints.stats,
        requiresAuth: true,
      );

      // Aquest bloc valida una resposta correcta del backend i transforma
      // les dades rebudes en l’entitat que utilitza la resta de l’aplicació.
      if (response.statusCode == 200) {
        final data = _tryParseJson(response.body);

        if (data == null) {
          throw const ApiException(
            'La resposta de les estadístiques no és vàlida',
            statusCode: 200,
          );
        }

        return UserStats.fromJson(data);
      }

      // Aquest bloc interpreta els errors retornats pel backend per mostrar
      // un missatge més clar quan les estadístiques no es poden carregar.
      final data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'han pogut carregar les estadístiques';

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
