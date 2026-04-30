part of 'api_client_impl.dart';

// Aquest mixin implementa la comunicació amb l’endpoint d’estadístiques.
// Manté la petició separada de la pantalla perquè la UI només treballi
// amb entitats del projecte i no amb respostes HTTP directes.
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

  // Aquest mètode recupera el resum necessari per construir el dashboard.
  // Fa servir el mateix endpoint de stats perquè el dashboard és una vista resumida del progrés.
  @override
  Future<DashboardSummary> getDashboardSummary() async {
    try {
      final response = await _getJson(
        ApiEndpoints.stats,
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = _tryParseJson(response.body);

        if (data == null) {
          throw const ApiException(
            'La resposta del dashboard no és vàlida',
            statusCode: 200,
          );
        }

        return DashboardSummary.fromJson(data);
      }

      final data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut carregar el dashboard';

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