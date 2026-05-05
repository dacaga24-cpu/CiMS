part of 'api_client_impl.dart';

// Aquest mixin implementa la comunicació amb l’endpoint del repte mensual.
// Manté aquesta petició separada del dashboard perquè el repte té un recurs propi al backend.
mixin _MonthlyChallengeApiClientImplMixin on _ApiClientBase
    implements MonthlyChallengeApiClient {
  // Aquest mètode recupera el repte mensual actiu de l’usuari autenticat.
  // La resposta es transforma en una entitat perquè la UI no depengui del JSON cru.
  @override
  Future<MonthlyChallenge> getCurrentMonthlyChallenge() async {
    try {
      final response = await _getJson(
        ApiEndpoints.currentMonthlyChallenge,
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = _tryParseJson(response.body);

        if (data == null) {
          throw const ApiException(
            'La resposta del repte mensual no és vàlida',
            statusCode: 200,
          );
        }

        return MonthlyChallenge.fromJson(data);
      }

      final data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut carregar el repte mensual';

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
